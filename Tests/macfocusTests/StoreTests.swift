import XCTest
@testable import macfocus

final class StoreTests: XCTestCase {
    var tmpDir: URL!
    var store: Store!

    override func setUpWithError() throws {
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("macfocus-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let path = tmpDir.appendingPathComponent("state.json")
        store = Store(path: path)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    func testReadReturnsNilWhenMissing() throws {
        XCTAssertFalse(store.exists())
        XCTAssertNil(try store.read())
    }

    func testWriteThenRead() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let s = FocusState(on: true, startedAt: now, duration: 25, notify: true)
        try store.write(s)
        XCTAssertTrue(store.exists())
        let got = try store.read()
        XCTAssertEqual(got?.on, true)
        XCTAssertEqual(got?.duration, 25)
        XCTAssertEqual(got?.notify, true)
        XCTAssertEqual(got?.startedAt.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1.0)
    }

    func testOverwriteState() throws {
        let s1 = FocusState(on: true, startedAt: Date(), duration: 10, notify: false)
        try store.write(s1)
        let s2 = FocusState(on: false, startedAt: Date(), duration: 99, notify: true)
        try store.write(s2)
        let got = try store.read()
        XCTAssertEqual(got?.on, false)
        XCTAssertEqual(got?.duration, 99)
    }

    func testClearRemovesFile() throws {
        let s = FocusState(on: true, startedAt: Date(), duration: 5, notify: false)
        try store.write(s)
        XCTAssertTrue(store.exists())
        try store.clear()
        XCTAssertFalse(store.exists())
    }

    func testElapsedMinutes() {
        let start = Date()
        let later = start.addingTimeInterval(60 * 7) // 7 min later
        XCTAssertEqual(FocusMath.elapsedMinutes(from: start, now: later), 7)
        XCTAssertEqual(FocusMath.elapsedMinutes(from: start, now: start), 0)
        // negative -> 0
        let earlier = start.addingTimeInterval(-60)
        XCTAssertEqual(FocusMath.elapsedMinutes(from: start, now: earlier), 0)
    }

    func testMinutesLeft() {
        let start = Date()
        let t = start.addingTimeInterval(60 * 10) // 10 min in
        XCTAssertEqual(FocusMath.minutesLeft(from: start, duration: 25, now: t), 15)
        let past = start.addingTimeInterval(60 * 30)
        XCTAssertEqual(FocusMath.minutesLeft(from: start, duration: 25, now: past), 0)
    }

    func testIsExpired() {
        let start = Date()
        XCTAssertFalse(FocusMath.isExpired(from: start, duration: 25, now: start.addingTimeInterval(60 * 5)))
        XCTAssertTrue(FocusMath.isExpired(from: start, duration: 25, now: start.addingTimeInterval(60 * 25)))
        XCTAssertTrue(FocusMath.isExpired(from: start, duration: 25, now: start.addingTimeInterval(60 * 30)))
    }

    func testEndTime() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = FocusMath.endTime(from: start, duration: 25)
        XCTAssertEqual(end.timeIntervalSince(start), 25 * 60, accuracy: 0.001)
    }
}

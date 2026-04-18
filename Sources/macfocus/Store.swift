import Foundation

public struct FocusState: Codable, Equatable {
    public var on: Bool
    public var startedAt: Date
    public var duration: Int // minutes
    public var notify: Bool

    public init(on: Bool, startedAt: Date, duration: Int, notify: Bool) {
        self.on = on
        self.startedAt = startedAt
        self.duration = duration
        self.notify = notify
    }
}

public enum StoreError: Error {
    case encodeFailed
    case decodeFailed
}

public struct Store {
    public let path: URL

    public init(path: URL) {
        self.path = path
    }

    public static func defaultPath() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/macfocus/state.json")
    }

    public static func `default`() -> Store {
        Store(path: defaultPath())
    }

    public func exists() -> Bool {
        FileManager.default.fileExists(atPath: path.path)
    }

    public func read() throws -> FocusState? {
        guard exists() else { return nil }
        let data = try Data(contentsOf: path)
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try dec.decode(FocusState.self, from: data)
    }

    public func write(_ state: FocusState) throws {
        let dir = path.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try enc.encode(state)
        try data.write(to: path, options: .atomic)
    }

    public func clear() throws {
        if exists() {
            try FileManager.default.removeItem(at: path)
        }
    }
}

public enum FocusMath {
    /// elapsed minutes since startedAt (floored).
    public static func elapsedMinutes(from start: Date, now: Date = Date()) -> Int {
        let s = Int(now.timeIntervalSince(start))
        return max(0, s / 60)
    }

    /// minutes remaining given a duration. clamps at 0.
    public static func minutesLeft(from start: Date, duration: Int, now: Date = Date()) -> Int {
        let left = duration - elapsedMinutes(from: start, now: now)
        return max(0, left)
    }

    /// is the session expired?
    public static func isExpired(from start: Date, duration: Int, now: Date = Date()) -> Bool {
        return now.timeIntervalSince(start) >= Double(duration * 60)
    }

    /// end time for a session (for the "reminder at HH:MM" string).
    public static func endTime(from start: Date, duration: Int) -> Date {
        return start.addingTimeInterval(Double(duration * 60))
    }
}

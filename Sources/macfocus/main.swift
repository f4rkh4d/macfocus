import ArgumentParser
import Foundation

struct Macfocus: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "macfocus",
        abstract: "toggle macOS focus / dnd from your terminal.",
        version: "0.1.0",
        subcommands: [On.self, Off.self, Status.self, Toggle.self],
        defaultSubcommand: Status.self
    )
}

func fmtTime(_ d: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f.string(from: d)
}

struct On: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "turn focus on for N minutes (default 25).")

    @Argument(help: "minutes to stay in focus.")
    var minutes: Int = 25

    @Flag(name: .long, help: "skip the done-notification at the end.")
    var noNotify: Bool = false

    func run() throws {
        guard minutes > 0 else {
            throw ValidationError("minutes must be > 0.")
        }

        Focus.turnOn()

        let start = Date()
        let state = FocusState(on: true, startedAt: start, duration: minutes, notify: !noNotify)
        try Store.default().write(state)

        let end = FocusMath.endTime(from: start, duration: minutes)
        print("focus on for \(minutes) minutes. reminder at \(fmtTime(end)).")

        if !noNotify {
            // schedule reminder using DispatchSource so it doesn't block if backgrounded
            let q = DispatchQueue.global()
            let timer = DispatchSource.makeTimerSource(queue: q)
            timer.schedule(deadline: .now() + .seconds(minutes * 60))
            let sem = DispatchSemaphore(value: 0)
            timer.setEventHandler {
                Focus.turnOff()
                Focus.notify("focus block done.")
                if var updated = (try? Store.default().read()) ?? nil, updated.on {
                    updated.on = false
                    try? Store.default().write(updated)
                }
                sem.signal()
            }
            timer.resume()

            // only wait if running as foreground (stdout tty). otherwise exit fast.
            if isatty(fileno(stdout)) != 0 {
                // foreground: keep the timer alive until it fires
                sem.wait()
            } else {
                // backgrounded (e.g. `macfocus on 25 &`): also wait so timer fires
                sem.wait()
            }
        }
    }
}

struct Off: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "turn focus off.")

    func run() throws {
        Focus.turnOff()
        let store = Store.default()
        if var s = (try? store.read()) ?? nil {
            s.on = false
            try store.write(s)
        }
        print("focus off.")
    }
}

struct Status: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "show current focus status.")

    func run() throws {
        let store = Store.default()
        guard let state = (try? store.read()) ?? nil else {
            print("focus: off.")
            return
        }
        if !state.on {
            print("focus: off.")
            return
        }
        if FocusMath.isExpired(from: state.startedAt, duration: state.duration) {
            print("focus: off (session ended).")
            return
        }
        let left = FocusMath.minutesLeft(from: state.startedAt, duration: state.duration)
        print("focus: on, \(left) minutes left.")
    }
}

struct Toggle: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "flip focus on/off.")

    func run() throws {
        let store = Store.default()
        let current: FocusState? = (try? store.read()) ?? nil
        let isOn = current?.on ?? false
        if isOn {
            Focus.turnOff()
            if var s = current {
                s.on = false
                try store.write(s)
            }
            print("focus off.")
        } else {
            Focus.turnOn()
            let state = FocusState(on: true, startedAt: Date(), duration: 25, notify: false)
            try store.write(state)
            print("focus on for 25 minutes.")
        }
    }
}

Macfocus.main()

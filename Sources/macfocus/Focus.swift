import Foundation

enum Focus {
    /// runs a shell command, returns (exitCode, stdout, stderr).
    @discardableResult
    static func shell(_ launchPath: String, _ args: [String]) -> (Int32, String, String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: launchPath)
        p.arguments = args
        let out = Pipe(); let err = Pipe()
        p.standardOutput = out
        p.standardError = err
        do {
            try p.run()
            p.waitUntilExit()
        } catch {
            return (-1, "", "\(error)")
        }
        let o = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let e = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (p.terminationStatus, o, e)
    }

    /// try shortcuts first, fall back to osascript dnd toggle.
    static func turnOn() {
        let (code, _, _) = shell("/usr/bin/shortcuts", ["run", "Turn On Focus"])
        if code != 0 {
            fallbackToggle()
        }
    }

    static func turnOff() {
        let (code, _, _) = shell("/usr/bin/shortcuts", ["run", "Turn Off Focus"])
        if code != 0 {
            fallbackToggle()
        }
    }

    /// fallback: use osascript to send a keystroke that toggles DND via Control Center.
    /// user can bind a Focus toggle shortcut in System Settings > Keyboard > Shortcuts.
    /// default uses cmd+opt+ctrl+shift+d (rare combo, user can change it).
    static func fallbackToggle() {
        let script = """
        tell application "System Events"
            key code 2 using {command down, option down, control down, shift down}
        end tell
        """
        shell("/usr/bin/osascript", ["-e", script])
    }

    static func notify(_ message: String, title: String = "macfocus") {
        let escaped = message.replacingOccurrences(of: "\"", with: "\\\"")
        let t = title.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "display notification \"\(escaped)\" with title \"\(t)\""
        shell("/usr/bin/osascript", ["-e", script])
    }
}

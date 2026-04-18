# macfocus

macOS only. small cli i made so i can flip on Do Not Disturb from the terminal without clicking through System Settings. pomodoro-ish but no ui, just a timer in the background.

## install

```
git clone https://github.com/f4rkh4d/macfocus.git
cd macfocus
swift build -c release
cp .build/release/macfocus /usr/local/bin
```

needs macOS 13+ and swift 5.9+.

## setup (once)

macfocus tries to run two Shortcuts: `Turn On Focus` and `Turn Off Focus`. make those in the Shortcuts app (they're one-click, pick a Focus mode and toggle it). if the shortcuts aren't there it falls back to an osascript keystroke, so you can also bind a DND toggle in System Settings > Keyboard > Shortcuts to `cmd+opt+ctrl+shift+d`.

## usage

```
macfocus on 25          # focus for 25 min, notifies when done
macfocus on             # defaults to 25
macfocus off            # end it early
macfocus status         # "focus: on, 17 minutes left."
macfocus toggle         # flip it
```

run it in the background so the reminder still fires:

```
macfocus on 50 &
```

state is saved to `~/.config/macfocus/state.json` so `status` works across sessions.

## why

i kept forgetting to turn dnd off after studying and my phone would blow up 3 hours later. this just nags me when my block is up.

mit license.

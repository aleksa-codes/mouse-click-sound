import AppKit

guard CommandLine.arguments.count == 3,
      ["check", "stop"].contains(CommandLine.arguments[1]) else {
    fputs("Usage: app-control.swift check|stop /path/to/app\n", stderr)
    exit(1)
}
let command = CommandLine.arguments[1]
let path = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL.resolvingSymlinksInPath()
let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "codes.aleksa.mouse-click-sound")
    .filter { $0.bundleURL?.standardizedFileURL.resolvingSymlinksInPath() == path }
if command == "check", !apps.isEmpty {
    fputs("This app is running. Use make run to quit, rebuild, and reopen it safely.\n", stderr)
    exit(1)
}
if command == "stop" {
    for app in apps {
        print("Quitting \(path.path) (PID \(app.processIdentifier))")
        guard app.terminate() else {
            fputs("Could not quit the app. Quit it from the menu bar, then retry.\n", stderr)
            exit(1)
        }
    }
    let deadline = Date().addingTimeInterval(8)
    while apps.contains(where: { !$0.isTerminated }), Date() < deadline {
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }
    if apps.contains(where: { !$0.isTerminated }) {
        fputs("The app has not quit. Build cancelled; no force quit was attempted.\n", stderr)
        exit(1)
    }
}

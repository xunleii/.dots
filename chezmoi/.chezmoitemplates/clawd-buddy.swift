// Clawd Buddy. Two modes, one binary:
//   clawd-buddy --browser [-d right|left|up|down] URL   client, runs inside the nono sandbox
//     (it cannot send Apple Events), asks the daemon to split THIS Ghostty pane.
//   clawd-buddy --authorize                             once, by hand: shows the macOS Automation
//     prompt (Clawd Buddy -> Ghostty). Relaunches the app through LaunchServices so the
//     prompt is attributed to Clawd Buddy, not to the terminal running this command.
//   no arguments                                        daemon, started by launchd.
// Daemon: launchd socket-activated, runs OUTSIDE the nono sandbox. Its input comes
// from the sandbox, so every field is validated before it reaches AppleScript.
// Request: v1<TAB>surface id<TAB>direction<TAB>url   Reply: ok | err <reason>
import AppKit

let authorizeResult = NSHomeDirectory() + "/.local/state/clawd-buddy.authorize"
let browser = "/opt/homebrew/bin/terminal-browser"

func askAutomation() -> OSStatus {
    let target = NSAppleEventDescriptor(bundleIdentifier: "com.mitchellh.ghostty")
    return AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, true)
}

func handle(_ line: String) -> String {
    let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
    guard f.count == 4, f[0] == "v1" else { return "err unsupported version" }
    let (sid, dir, url) = (f[1], f[2], f[3])
    guard ["right", "left", "up", "down"].contains(dir) else { return "err bad direction" }
    guard url.hasPrefix("http://") || url.hasPrefix("https://"),
          !url.unicodeScalars.contains(where: { "'\"\\`".unicodeScalars.contains($0) || $0.properties.isWhitespace || $0.value < 32 })
    else { return "err bad url" }
    guard sid.unicodeScalars.allSatisfy({ ($0.isASCII && $0.properties.isAlphabetic) || ("0"..."9").contains($0) || $0 == "-" })
    else { return "err bad surface id" }

    let src = """
    tell application "Ghostty"
      set cfg to new surface configuration
      set command of cfg to "'\(browser)' open '\(url)'"
      try
        set t to first terminal whose id is "\(sid)"
      on error
        set t to focused terminal of selected tab of front window
      end try
      split t direction \(dir) with configuration cfg
    end tell
    """
    var ok = false
    DispatchQueue.main.sync { // NSAppleScript is main-thread only
        // A launchd agent never gets the Automation prompt from a plain script run: ask for it.
        let perm = askAutomation()
        guard perm == noErr else {
            FileHandle.standardError.write(Data("automation to Ghostty denied (\(perm))\n".utf8))
            return
        }
        var err: NSDictionary?
        ok = NSAppleScript(source: src)?.executeAndReturnError(&err) != nil
        if let err { FileHandle.standardError.write(Data("\(err)\n".utf8)) }
    }
    return ok ? "ok" : "err ghostty"
}

func serve(_ fd: Int32) {
    var buf = [UInt8](repeating: 0, count: 4096)
    var n = 0
    while n < buf.count { // ponytail: no timeout, a stalled client holds one thread
        let r = read(fd, &buf[n], buf.count - n)
        if r <= 0 { break }
        n += r
        if buf[..<n].contains(10) { break }
    }
    let line = String(decoding: buf[..<n].prefix { $0 != 10 }, as: UTF8.self)
    let reply = Array((handle(line) + "\n").utf8)
    _ = write(fd, reply, reply.count)
    close(fd)
}

func client(_ argv: [String]) -> Int32 {
    var args = argv.filter { $0 != "--browser" }
    var dir = "right"
    if args.first == "-d", args.count >= 3 { dir = args[1]; args.removeFirst(2) }
    guard args.count == 1 else {
        FileHandle.standardError.write(Data("usage: clawd-buddy --browser [-d right|left|up|down] URL\n".utf8))
        return 2
    }
    let sid = ProcessInfo.processInfo.environment["GHOSTTY_SURFACE_ID"] ?? "none"
    let path = NSHomeDirectory() + "/.local/state/clawd-buddy.sock"
    var addr = sockaddr_un()
    addr.sun_family = sa_family_t(AF_UNIX)
    withUnsafeMutableBytes(of: &addr.sun_path) { $0.copyBytes(from: path.utf8.prefix($0.count - 1)) }
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    let linked = withUnsafePointer(to: &addr) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
    }
    guard linked == 0 else { FileHandle.standardError.write(Data("clawd-buddy: daemon unreachable (\(String(cString: strerror(errno))))\n".utf8)); return 1 }
    let req = Array("v1\t\(sid)\t\(dir)\t\(args[0])\n".utf8)
    _ = write(fd, req, req.count)
    var buf = [UInt8](repeating: 0, count: 256)
    let n = max(read(fd, &buf, buf.count), 0)
    let reply = String(decoding: buf[..<n], as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    if reply == "ok" { return 0 }
    FileHandle.standardError.write(Data("clawd-buddy: \(reply)\n".utf8))
    return 1
}

if CommandLine.arguments.dropFirst().first == "--authorize" {
    // argv[0] may be the ~/.local/bin symlink or a bare name: realpath the kernel-reported path.
    let raw = Bundle.main.executablePath ?? CommandLine.arguments[0]
    let exe = URL(fileURLWithPath: realpath(raw, nil).map { String(cString: $0) } ?? raw)
    let bundle = exe.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    try? FileManager.default.removeItem(atPath: authorizeResult)
    // A past denial is sticky (-1743, no prompt): forget it so the prompt can show again.
    let reset = Process()
    reset.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
    reset.arguments = ["reset", "AppleEvents", "dev.axnic.clawd-buddy"]
    reset.standardOutput = FileHandle.nullDevice
    try reset.run()
    reset.waitUntilExit()
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    p.arguments = ["-W", "-n", "-a", bundle.path, "--args", "--authorize-run"]
    try p.run()
    p.waitUntilExit()
    // `open` can't carry the app's stdout back, so the app leaves its verdict in a file.
    let verdict = (try? String(contentsOfFile: authorizeResult, encoding: .utf8)) ?? "no answer from Clawd Buddy\n"
    print("clawd-buddy: automation to Ghostty \(verdict)", terminator: "")
    exit(verdict.hasPrefix("granted") ? 0 : 1)
}
if CommandLine.arguments.dropFirst().first == "--authorize-run" { // started by LaunchServices
    DispatchQueue.global().async {
        let r = askAutomation()
        try? (r == noErr ? "granted\n" : "denied (\(r))\n").write(toFile: authorizeResult, atomically: true, encoding: .utf8)
        exit(r == noErr ? 0 : 1)
    }
    NSApplication.shared.run()
}
if CommandLine.arguments.count > 1 { exit(client(Array(CommandLine.arguments.dropFirst()))) }

var fds = UnsafeMutablePointer<Int32>.allocate(capacity: 1) // overwritten by launchd
var count = 0
guard launch_activate_socket("Listeners", &fds, &count) == 0, count > 0, case let listener = fds[0] else {
    FileHandle.standardError.write(Data("clawd-buddy: no launchd socket\n".utf8))
    exit(1)
}
DispatchQueue.global().async {
    while true {
        let c = accept(listener, nil, nil)
        if c >= 0 { DispatchQueue.global().async { serve(c) } }
    }
}
// AppKit would otherwise SIGTERM this idle agent a moment after launch.
ProcessInfo.processInfo.disableSuddenTermination()
ProcessInfo.processInfo.disableAutomaticTermination("socket daemon")
NSApplication.shared.run()

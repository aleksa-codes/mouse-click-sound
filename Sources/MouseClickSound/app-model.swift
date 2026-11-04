import AppKit
import Combine
import CoreGraphics
import ServiceManagement

@MainActor
final class AppModel: ObservableObject {
    private enum MouseButton: Equatable {
        case left
        case right
    }

    @Published var enabled: Bool {
        didSet {
            UserDefaults.standard.set(enabled, forKey: "enabled")
            refreshMonitoring()
        }
    }
    @Published var volume: Double {
        didSet { UserDefaults.standard.set(volume, forKey: "volume") }
    }
    @Published private(set) var monitoring = false
    @Published private(set) var permissionGranted = false
    @Published private(set) var loginEnabled = false
    @Published private(set) var loginNeedsApproval = false
    @Published var errorMessage: String?
    var menuOpen = false {
        didSet { if menuOpen { resetGesture() } }
    }

    private let monitor = MouseMonitor()
    private var player: SoundPlayer?
    private var origin: CGPoint?
    private var activeButton: MouseButton?
    private var pressed = false
    private var holdTimer: Timer?

    init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: ["enabled": true, "volume": 0.45])
        enabled = defaults.bool(forKey: "enabled")
        volume = min(1, max(0, defaults.double(forKey: "volume")))
        do { player = try SoundPlayer() }
        catch { errorMessage = "Could not load the bundled sounds: \(error.localizedDescription)" }
        monitor.onEvent = { [weak self] type, location, isOwnEvent in
            self?.handle(type, at: location, isOwnEvent: isOwnEvent)
        }
        monitor.onInterruption = { [weak self] in self?.resetGesture() }
        refreshMonitoring()
        refreshLoginStatus()
    }

    func refreshMonitoring() {
        permissionGranted = CGPreflightListenEventAccess()
        if enabled && permissionGranted && player != nil {
            monitoring = monitor.start()
            if !monitoring { errorMessage = "Mouse monitoring could not start. Check Input Monitoring permission, then quit and reopen the app." }
        } else {
            monitor.stop()
            monitoring = false
        }
    }

    func requestPermission() {
        _ = CGRequestListenEventAccess()
        refreshMonitoring()
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else { return }
        NSWorkspace.shared.open(url)
    }

    func refreshLoginStatus() {
        let status = SMAppService.mainApp.status
        loginEnabled = status == .enabled || status == .requiresApproval
        loginNeedsApproval = status == .requiresApproval
    }

    func setLoginEnabled(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            errorMessage = "Could not update launch at login: \(error.localizedDescription)"
        }
        refreshLoginStatus()
    }

    func preview(_ sound: Sound) { player?.play(sound, volume: volume) }

    private func handle(_ type: CGEventType, at location: CGPoint, isOwnEvent: Bool) {
        guard enabled, monitoring, !menuOpen else { return }
        guard let button = button(for: type) else { return }
        switch type {
        case .leftMouseDown, .rightMouseDown:
            resetGesture()
            // Do not add global sounds to this app's own preview controls.
            guard !isOwnEvent else { return }
            activeButton = button
            origin = location
            // A short tap is one intact recording. Only a hold or drag
            // commits to separate sounds, so taps cannot stack the halves.
            let timer = Timer(timeInterval: 0.18, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.beginHold() }
            }
            holdTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        case .leftMouseDragged, .rightMouseDragged:
            guard activeButton == button, let origin else { return }
            if hypot(location.x - origin.x, location.y - origin.y) >= 4 { beginHold() }
        case .leftMouseUp, .rightMouseUp:
            guard activeButton == button, origin != nil else { return }
            player?.play(pressed ? .release : .click, volume: volume)
            resetGesture()
        default: break
        }
    }

    private func button(for type: CGEventType) -> MouseButton? {
        switch type {
        case .leftMouseDown, .leftMouseDragged, .leftMouseUp: .left
        case .rightMouseDown, .rightMouseDragged, .rightMouseUp: .right
        default: nil
        }
    }

    private func beginHold() {
        guard origin != nil, !pressed else { return }
        holdTimer?.invalidate()
        holdTimer = nil
        pressed = true
        player?.play(.press, volume: volume)
    }

    func resetGesture() {
        holdTimer?.invalidate()
        holdTimer = nil
        origin = nil
        activeButton = nil
        pressed = false
    }

    func suspend() {
        monitor.stop()
        monitoring = false
        player?.stop()
    }
}

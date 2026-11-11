import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    private var model: AppModel?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var subscription: AnyCancellable?
    private let enableItem = NSMenuItem(title: "Enable sounds", action: #selector(toggleSounds), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Mouse Click Sound")
        let appSettings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        appSettings.target = self
        appMenu.addItem(appSettings)
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Mouse Click Sound", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Close Settings", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = windowMenu
        let model = AppModel()
        self.model = model
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem
        if let iconURL = Bundle.main.url(forResource: "MenuIcon", withExtension: "tiff"),
           let image = NSImage(contentsOf: iconURL) {
            image.size = NSSize(width: 24, height: 18)
            image.isTemplate = true
            image.accessibilityDescription = "Mouse Click Sound"
            statusItem.button?.image = image
        } else {
            statusItem.button?.image = NSImage(systemSymbolName: "cursorarrow.click", accessibilityDescription: "Mouse Click Sound")
        }
        let menu = NSMenu()
        menu.delegate = self
        enableItem.target = self
        menu.addItem(enableItem)
        menu.addItem(.separator())
        let settings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Mouse Click Sound", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
        subscription = model.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateStatus()
                self?.resizeSettingsWindowToFitContent()
            }
        }
        updateStatus()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSApplication.didBecomeActiveNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleep), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refresh), name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleep), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refresh), name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
        if !model.permissionGranted || model.errorMessage != nil { showSettings() }
    }

    private func updateStatus() {
        guard let model else { return }
        enableItem.state = model.enabled ? .on : .off
        statusItem?.button?.appearsDisabled = !model.monitoring
        statusItem?.button?.toolTip = model.monitoring ? "Mouse Click Sound: enabled" : "Mouse Click Sound: paused or permission needed"
    }

    private func resizeSettingsWindowToFitContent() {
        guard let window = settingsWindow, let contentView = window.contentView else { return }
        contentView.layoutSubtreeIfNeeded()
        let fittingSize = contentView.fittingSize
        guard fittingSize.height > 0, abs(contentView.bounds.height - fittingSize.height) > 1 else { return }
        window.setContentSize(NSSize(width: SettingsView.windowWidth, height: fittingSize.height))
    }

    @objc private func toggleSounds() { model?.enabled.toggle() }

    @objc private func showSettings() {
        guard let model else { return }
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: SettingsView.windowWidth, height: 300), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "Mouse Click Sound"
            let contentView = NSHostingView(rootView: SettingsView(model: model))
            contentView.sizingOptions = .intrinsicContentSize
            window.contentView = contentView
            window.setContentSize(contentView.fittingSize)
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            settingsWindow = window
        }
        model.refreshLoginStatus()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if settingsWindow?.isMiniaturized == true { settingsWindow?.deminiaturize(nil) }
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.makeFirstResponder(nil)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    func menuWillOpen(_ menu: NSMenu) { model?.menuOpen = true; updateStatus() }
    func menuDidClose(_ menu: NSMenu) { model?.menuOpen = false }
    @objc private func sleep() { model?.suspend() }
    @objc private func refresh() {
        model?.refreshMonitoring()
        model?.refreshLoginStatus()
    }
    @objc private func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) { model?.suspend() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

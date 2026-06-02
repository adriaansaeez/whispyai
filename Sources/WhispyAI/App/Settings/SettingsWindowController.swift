import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    func show(appState: AppState) {
        let window = window ?? makeWindow(appState: appState)

        if let hostingController = window.contentViewController as? NSHostingController<SettingsRootView> {
            hostingController.rootView = SettingsRootView(appState: appState)
        } else {
            window.contentViewController = NSHostingController(rootView: SettingsRootView(appState: appState))
        }

        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeMain()
        window.orderFrontRegardless()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hide(sender)
        return false
    }

    func windowWillMiniaturize(_ notification: Notification) {
        guard let window else { return }
        hide(window)
    }

    private func makeWindow(appState: AppState) -> NSWindow {
        let hostingController = NSHostingController(rootView: SettingsRootView(appState: appState))
        let window = NSWindow(contentViewController: hostingController)
        window.delegate = self
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 560, height: 380))
        window.contentMinSize = NSSize(width: 560, height: 380)
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.center()
        window.collectionBehavior = [.moveToActiveSpace]
        self.window = window
        return window
    }

    private func hide(_ window: NSWindow) {
        window.orderOut(nil)
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

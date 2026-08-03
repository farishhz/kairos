import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private static var shared: SettingsWindowController?
    private static var pendingTab: SettingsTab?

    static func show(tab: SettingsTab? = nil) {
        pendingTab = tab

        if shared == nil {
            shared = SettingsWindowController()
        }

        shared?.showWindow(nil)
    }

    private init() {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: CGSize(width: 860, height: 580)),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)
        configureWindow()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureWindow() {
        guard let window else { return }

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.setFrameAutosaveName("KairosSettingsWindow")
        window.minSize = NSSize(width: 860, height: 580)
        window.center()
        window.delegate = self

        let rootView = SettingsView(initialTab: Self.pendingTab)
        window.contentViewController = NSHostingController(rootView: rootView)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        AppActivationPolicy.enter()
    }

    func windowWillClose(_ notification: Notification) {
        AppActivationPolicy.leave()
        Self.pendingTab = nil
        Self.shared = nil
    }
}

import AppKit

@MainActor
enum AppActivationPolicy {
    private static var count = 0

    static func enter() {
        count += 1
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    static func leave() {
        count = max(0, count - 1)
        // swiftlint:disable:next empty_count
        if count > 0 { return }
        Task { @MainActor in
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

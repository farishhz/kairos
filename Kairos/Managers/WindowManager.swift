import Cocoa
import Combine
import SwiftUI

@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()
    let objectWillChange = ObservableObjectPublisher()

    var floatingWindow: NSWindow?

    func showFloating() {
        if self.floatingWindow != nil { return }

        self.objectWillChange.send()

        let contentSize = CGSize(
            width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
            height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)

        let contentView = FloatingTimerView()

        let window = NSPanel(
            contentRect: NSRect(x: 100, y: 600, width: contentSize.width, height: contentSize.height),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false)

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
        ]

        // Hosting View
        window.contentView = NSHostingView(rootView: contentView)
        window.orderFrontRegardless()

        self.floatingWindow = window
    }

    func hideFloating() {
        guard self.floatingWindow != nil else { return }
        self.objectWillChange.send()
        self.floatingWindow?.orderOut(nil)
        self.floatingWindow = nil
    }



    func updateFloatingSize() {
        guard let window = floatingWindow else { return }
        let size = CGSize(
            width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
            height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().setContentSize(size)
        }
    }
}

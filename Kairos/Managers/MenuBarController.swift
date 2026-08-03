import Cocoa
import Combine
import SwiftUI

private final class MenuBarPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}

private final class EdgeToEdgeHostingView<Content: View>: NSHostingView<Content> {
    override var safeAreaInsets: NSEdgeInsets {
        .init(top: 0, left: 0, bottom: 0, right: 0)
    }
}

private final class EdgeToEdgeHostingController<Content: View>: NSHostingController<Content> {
    override func loadView() {
        self.view = EdgeToEdgeHostingView(rootView: self.rootView)
    }
}

@MainActor
final class MenuBarController: NSObject {
    static var shared: MenuBarController?

    private let statusItem: NSStatusItem
    private let panel: MenuBarPanel
    private let session = FocusSessionManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?
    private var compactDzIcon: NSImage?

    override init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.panel = MenuBarPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: AppConstants.MenuBarSettings.panelWidth,
                height: AppConstants.MenuBarSettings.panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)

        super.init()

        if let button = statusItem.button {
            button.action = #selector(self.togglePopover(_:))
            button.target = self
        }

        self.panel.isFloatingPanel = true
        self.panel.level = .popUpMenu
        self.panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.panel.hidesOnDeactivate = true
        self.panel.hasShadow = true
        self.panel.backgroundColor = .clear
        self.panel.isOpaque = false
        let rootView = MenuBarView()
            .ignoresSafeArea()
        let hostingController = EdgeToEdgeHostingController(rootView: rootView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        self.panel.contentViewController = hostingController
        self.installClickMonitors()

        MenuBarController.shared = self

        self.bindStatusUpdates()
        self.updateStatusItem()
    }

    deinit {
        MainActor.assumeIsolated {
            self.removeClickMonitors()
        }
    }

    @objc private func togglePopover(_: Any?) {
        if self.panel.isVisible {
            self.closePanel()
        } else {
            self.showPopover()
        }
    }

    func showPopover() {
        self.positionPanelBelowStatusItem()
        self.panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openLegacySettingsWindow() {
        self.closePanel()
        DispatchQueue.main.async {
            SettingsWindowController.show()
        }
    }

    private func closePanel() {
        self.panel.orderOut(nil)
    }

    private func positionPanelBelowStatusItem() {
        guard let buttonFrame = self.statusButtonFrameInScreen() else { return }

        let panelSize = NSSize(
            width: AppConstants.MenuBarSettings.panelWidth,
            height: AppConstants.MenuBarSettings.panelHeight)
        let spacing: CGFloat = 6
        var origin = NSPoint(
            x: buttonFrame.midX - (panelSize.width / 2),
            y: buttonFrame.minY - panelSize.height - spacing)

        if let screen = NSScreen.screens.first(where: { $0.frame.intersects(buttonFrame) })
            ?? NSScreen.main
        {
            let visible = screen.visibleFrame
            let minX = visible.minX
            let maxX = visible.maxX - panelSize.width
            origin.x = min(max(origin.x, minX), maxX)
            if origin.y < visible.minY {
                origin.y = buttonFrame.maxY + spacing
            }
        }

        self.panel.setFrame(NSRect(origin: origin, size: panelSize), display: true)
    }

    private func statusButtonFrameInScreen() -> NSRect? {
        guard let button = self.statusItem.button, let window = button.window else { return nil }
        let frameInWindow = button.convert(button.bounds, to: nil)
        return window.convertToScreen(frameInWindow)
    }

    private func installClickMonitors() {
        self.localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown])
            { [weak self] event in
                guard let self else { return event }
                self.dismissPanelIfNeeded(for: event)
                return event
            }

        self.globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown])
            { [weak self] event in
                self?.dismissPanelIfNeeded(for: event)
            }
    }

    private func removeClickMonitors() {
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
    }

    private func dismissPanelIfNeeded(for event: NSEvent) {
        guard self.panel.isVisible else { return }

        let screenPoint: NSPoint = if let eventWindow = event.window {
            eventWindow.convertPoint(toScreen: event.locationInWindow)
        } else {
            NSEvent.mouseLocation
        }

        let clickInsidePanel = self.panel.frame.contains(screenPoint)
        guard let statusButtonFrame = self.statusButtonFrameInScreen() else {
            return
        }
        let clickInsideStatusItem = statusButtonFrame.contains(screenPoint)
        if !clickInsidePanel, !clickInsideStatusItem {
            self.closePanel()
        }
    }

    private func bindStatusUpdates() {
        self.session.timerService.$remainingTime
            .sink { [weak self] _ in self?.updateStatusItem() }
            .store(in: &self.cancellables)

        self.session.timerService.$isRunning
            .sink { [weak self] _ in self?.updateStatusItem() }
            .store(in: &self.cancellables)

        self.session.timerService.$isPaused
            .sink { [weak self] _ in self?.updateStatusItem() }
            .store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in self?.updateStatusItem() }
            .store(in: &self.cancellables)
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else { return }

        let defaults = UserDefaults.standard
        let compact = defaults.object(forKey: AppConstants.MenuBarSettings.compactIconKey) as? Bool
            ?? true

        if compact {
            button.title = ""
            button.image = self.makeCompactDzIcon()
            self.statusItem.length = NSStatusItem.variableLength
            self.clearStatusWrapper(on: button)
        } else {
            button.image = nil
            button.title = self.currentMenuBarTitle()
            self.applyStatusWrapper(on: button)
            let targetWidth = max(28, button.intrinsicContentSize.width + 4)
            self.statusItem.length = targetWidth
        }
    }

    private func currentMenuBarTitle() -> String {
        let remaining = self.session.timerService.remainingTime
        let isActive = self.session.timerService.isRunning || self.session.timerService.isPaused
        if isActive, remaining > 0 {
            return self.formatTime(remaining)
        }

        let defaults = UserDefaults.standard
        let presetMinutes = defaults.object(
            forKey: AppConstants.MenuBarSettings.selectedPresetMinutesKey) as? Int
            ?? AppConstants.MenuBarSettings.defaultPresetMinutes
        return String(format: "%d:00", max(0, presetMinutes))
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func applyStatusWrapper(on button: NSStatusBarButton) {
        button.wantsLayer = true
        button.layer?.cornerRadius = 4
        button.layer?.borderWidth = 1
        button.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
        button.layer?.backgroundColor = NSColor.clear.cgColor
    }

    private func clearStatusWrapper(on button: NSStatusBarButton) {
        button.layer?.borderWidth = 0
        button.layer?.borderColor = nil
        button.layer?.backgroundColor = nil
        button.wantsLayer = false
    }

    private func makeCompactDzIcon() -> NSImage {
        if let compactDzIcon {
            return compactDzIcon
        }

        let text = "Q"
        let targetSize = NSSize(width: 16, height: 16)
        let cornerRadius: CGFloat = 4

        // Draw a white rounded-rect, then "punch out" the text to create a cut-out look.
        let image = NSImage(size: targetSize, flipped: false) { rect in
            let bgRect = rect.insetBy(dx: 0.5, dy: 0.5)
            let path = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)

            NSColor.white.setFill()
            path.fill()

            let font = NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black,
            ]

            let string = NSString(string: text)
            let textSize = string.size(withAttributes: attributes)
            let drawPoint = NSPoint(
                x: rect.midX - (textSize.width / 2),
                y: rect.midY - (textSize.height / 2) - 0.5)

            let context = NSGraphicsContext.current
            let priorOp = context?.compositingOperation ?? .sourceOver
            context?.compositingOperation = .destinationOut
            string.draw(at: drawPoint, withAttributes: attributes)
            context?.compositingOperation = priorOp

            // Subtle border so it remains visible on light menu bars.
            NSColor.black.withAlphaComponent(0.18).setStroke()
            path.lineWidth = 1
            path.stroke()

            return true
        }

        image.isTemplate = false
        self.compactDzIcon = image
        return image
    }
}

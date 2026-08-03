import AppKit
import OSLog

final class WindowDetectionService {
    static let shared = WindowDetectionService()

    private init() {}

    func isFloatingWindow(app: NSRunningApplication) -> Bool {
        let pid = app.processIdentifier

        if let bundleId = app.bundleIdentifier,
           AppConstants.AnalyticsSettings.knownFloatingApps.contains(bundleId) {
            return true
        }

        return hasFloatingWindowLayer(pid: pid)
    }

    private func hasFloatingWindowLayer(pid: pid_t) -> Bool {
        guard let infoList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }

        var hasFloatingWindow = false
        var hasNormalWindow = false

        for window in infoList {
            guard let windowPid = window[kCGWindowOwnerPID as String] as? pid_t,
                  windowPid == pid,
                  let layer = window[kCGWindowLayer as String] as? Int,
                  let isOnScreen = window[kCGWindowIsOnscreen as String] as? Bool,
                  isOnScreen else {
                continue
            }

            if layer <= CGWindowLevelKey.normalWindow.rawValue {
                hasNormalWindow = true
                Logger.tracking.debug("Normal window found: pid=\(pid) — not floating")
                break
            }

            hasFloatingWindow = true
            Logger.tracking.debug("Found elevated window: pid=\(pid) layer=\(layer)")
        }

        // Only floating if NO normal-level window exists
        if hasFloatingWindow && !hasNormalWindow {
            Logger.tracking.debug("Floating window confirmed: pid=\(pid)")
            return true
        }

        return false
    }
}

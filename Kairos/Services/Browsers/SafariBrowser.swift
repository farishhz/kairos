import Foundation
import OSLog

class SafariBrowser: BaseBrowser {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.farishhz.kairos", category: "SafariBrowser")

    init() {
        super.init(bundleId: "com.apple.Safari", displayName: "Safari")
    }

    override var currentURLScript: String {
        return """
            tell application "Safari"
                if (count of windows) > 0 then
                    set currentTab to current tab of window 1
                    return URL of currentTab
                end if
            end tell
            """
    }

    override func isInPrivateBrowsingMode() -> Bool? {
        let systemEventsScript = """
            tell application "System Events"
              tell process "Safari"
                  set theMenuBar to menu bar 1
                  set theWindowMenu to menu "Window" of theMenuBar
                  return (menu item "Move Tab to New Private Window" of theWindowMenu) exists
              end tell
            end tell
            """

        let scriptResult = executeAppleScript(systemEventsScript)

        if let error = scriptResult.error {
            if scriptResult.errorCode == -1719 {
                logger.debug("Safari System Events transient error (invalid index): \(error.description)")
                return nil
            } else if scriptResult.errorCode == -1712 {
                logger.debug("Safari System Events AppleScript timed out")
                return nil
            } else if scriptResult.errorCode == -1743 || scriptResult.errorCode == -1744 {
                AnalyticsPermissionsManager.shared.handleSystemEventsPermissionResult(success: false)
            } else if scriptResult.errorCode == -25211 {
                AnalyticsPermissionsManager.shared.handleAccessibilityPermissionResult(success: false)
            } else {
                logger.error("Safari System Events AppleScript error: \(error.description)")
            }
            return nil
        }

        if scriptResult.result != nil {
            AnalyticsPermissionsManager.shared.handleSystemEventsPermissionResult(success: true)
            AnalyticsPermissionsManager.shared.handleAccessibilityPermissionResult(success: true)
        }

        if let resultString = scriptResult.result,
           let isPrivate = Bool(resultString.lowercased()) {
            return isPrivate
        }

        return nil
    }
}

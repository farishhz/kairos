import Foundation
import AppKit
import OSLog

/// Firefox-specific implementation using System Events AppleScript.
/// Unlike Chromium-based browsers, Firefox does not expose tabs or URLs through
/// its direct AppleScript dictionary. Instead, this reads the address bar via
/// System Events accessibility. Requires `accessibility.force_disabled` set to `-1`
/// in Firefox's about:config for the accessibility tree to be available.
class FirefoxBrowser: BaseBrowser {

    /// Private browsing suffix appended to Firefox window titles
    private static let privateBrowsingSuffix = "\u{2014} Private Browsing"

    init() {
        super.init(bundleId: "org.mozilla.firefox", displayName: "Firefox")
    }

    /// Not used — Firefox overrides getCurrentURL() directly since it uses
    /// System Events instead of direct browser AppleScript.
    override var currentURLScript: String {
        return ""
    }

    override func getCurrentURL() -> String? {
        let script = """
            tell application "System Events" to tell process "Firefox"
                if not (exists window 1) then
                    error "Firefox accessibility tree not available" number -2700
                end if

                set frontWindow to window 1
                if (count of UI elements of frontWindow) is 0 then
                    error "Firefox accessibility tree not available" number -2700
                end if

                try
                    set addressValue to value of combo box 1 of group 1 of toolbar 2 of group 1 of frontWindow
                    if addressValue is not missing value and addressValue is not "" then return addressValue as text
                end try

                try
                    set addressValue to value of combo box 1 of group 1 of toolbar 1 of group 1 of frontWindow
                    if addressValue is not missing value and addressValue is not "" then return addressValue as text
                end try

                try
                    set addressValue to value of combo box 1 of toolbar 1 of frontWindow
                    if addressValue is not missing value and addressValue is not "" then return addressValue as text
                end try

                try
                    set addressValue to value of combo box 1 of toolbar 2 of frontWindow
                    if addressValue is not missing value and addressValue is not "" then return addressValue as text
                end try

                repeat with currentToolbar in toolbars of frontWindow
                    try
                        set addressValue to value of combo box 1 of currentToolbar
                        if addressValue is not missing value and addressValue is not "" then return addressValue as text
                    end try

                    repeat with currentGroup in groups of currentToolbar
                        try
                            set addressValue to value of combo box 1 of currentGroup
                            if addressValue is not missing value and addressValue is not "" then return addressValue as text
                        end try
                    end repeat
                end repeat

                return ""
            end tell
            """

        let scriptResult = executeAppleScript(script)

        if let error = scriptResult.error {
            let errorMessage = error[NSAppleScript.errorMessage] as? String ?? error.description

            if errorMessage.contains("Firefox accessibility tree not available") {
                Logger.browser.warning("Firefox accessibility tree not available. Set accessibility.force_disabled to -1 in about:config.")
                AnalyticsPermissionsManager.shared.handleBrowserError(
                    "Firefox requires setup: open about:config and set accessibility.force_disabled to -1.")
            } else if scriptResult.errorCode == -1712 {
                Logger.browser.debug("Firefox Accessibility AppleScript timed out")
            } else if scriptResult.errorCode == -1743 || scriptResult.errorCode == -1744 {
                AnalyticsPermissionsManager.shared.handleBrowserPermissionResult(
                    success: false, browserName: displayName)
            } else if scriptResult.errorCode == -25211 {
                AnalyticsPermissionsManager.shared.handleAccessibilityPermissionResult(success: false)
            } else if scriptResult.errorCode == -1719 || scriptResult.errorCode == -1728 {
                Logger.browser.debug(
                    "Firefox address bar unavailable in current accessibility tree: \(error.description)")
            } else {
                Logger.browser.error("Firefox Accessibility AppleScript error: \(error.description)")
                AnalyticsPermissionsManager.shared.handleBrowserError(
                    "Firefox communication error: \(error.description)")
            }
            return nil
        }

        if scriptResult.result != nil {
            AnalyticsPermissionsManager.shared.handleSystemEventsPermissionResult(success: true)
            AnalyticsPermissionsManager.shared.handleAccessibilityPermissionResult(success: true)
        }

        guard let urlValue = scriptResult.result, !urlValue.isEmpty else {
            return nil
        }

        // Filter out Firefox internal pages
        if urlValue.hasPrefix("about:") {
            return nil
        }

        // Firefox displays URLs without the scheme in the address bar
        if urlValue.hasPrefix("http://") || urlValue.hasPrefix("https://") {
            return urlValue
        }
        return "https://\(urlValue)"
    }

    override func isInPrivateBrowsingMode() -> Bool? {
        let script = """
            tell application "Firefox" to return name of front window
            """

        let scriptResult = executeAppleScript(script)

        guard let windowName = scriptResult.result else {
            return nil
        }

        return windowName.hasSuffix(Self.privateBrowsingSuffix)
    }
}

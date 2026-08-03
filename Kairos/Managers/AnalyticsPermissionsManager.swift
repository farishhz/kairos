import Foundation
import Combine
import AppKit
import OSLog

/// Status of macOS system permissions required for app functionality.
/// Used to track automation permissions needed for browser integration.
enum PermissionStatus {
    /// Permission has been granted by the user
    case granted
    /// Permission has been explicitly denied by the user
    case denied
    /// Permission status has not yet been determined
    case notDetermined
}

/// Manages macOS system permissions required for browser automation and website tracking.
/// Monitors AppleScript automation permissions and provides UI feedback for permission states.
/// Coordinates with BrowserActivityResolver to handle browser communication errors.
final class AnalyticsPermissionsManager: ObservableObject {
    static let shared = AnalyticsPermissionsManager()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.farishhz.kairos",
        category: "PermissionManager"
    )

    /// Current status of automation permissions for browser AppleScript access
    @Published var automationPermissionStatus: PermissionStatus = .notDetermined
    /// Current status of System Events automation permissions (needed for Safari private browsing detection)
    @Published var systemEventsPermissionStatus: PermissionStatus = .notDetermined
    /// Current status of Accessibility permissions (needed for Safari private browsing detection)
    @Published var accessibilityPermissionStatus: PermissionStatus = .notDetermined
    /// Most recent error message from browser communication attempts
    @Published var lastError: String?

    private init() {
        // Don't check permissions on init — let background tracking handle it
    }

    /// Updates permission status based on browser AppleScript execution results.
    /// Called by WebTrackingService when AppleScript operations succeed or fail.
    /// - Parameter success: Whether the AppleScript operation was successful
    func handleBrowserPermissionResult(success: Bool, browserName: String? = nil) {
        Task { @MainActor in
            if success {
                self.automationPermissionStatus = .granted
                self.lastError = nil
            } else {
                self.automationPermissionStatus = .denied
                let browser = browserName ?? "browser"
                self.lastError = "Automation permission needed for \(browser)"
                self.logger.error("Browser permission failed for \(browser, privacy: .public)")
            }
        }
    }

    /// Updates System Events permission status based on AppleScript execution results.
    /// Called by Safari browser when System Events operations succeed or fail.
    /// - Parameter success: Whether the System Events AppleScript operation was successful
    func handleSystemEventsPermissionResult(success: Bool) {
        Task { @MainActor in
            if success {
                self.systemEventsPermissionStatus = .granted
            } else {
                self.systemEventsPermissionStatus = .denied
                self.logger.error("System Events permission denied")
            }
        }
    }

    /// Updates Accessibility permission status based on AppleScript execution results.
    /// Called by Safari browser when Accessibility operations succeed or fail.
    /// - Parameter success: Whether the Accessibility operation was successful
    func handleAccessibilityPermissionResult(success: Bool) {
        Task { @MainActor in
            if success {
                self.accessibilityPermissionStatus = .granted
            } else {
                self.accessibilityPermissionStatus = .denied
                self.logger.error("Accessibility permission denied")
            }
        }
    }

    /// Checks if accessibility permissions are granted and prompts if not.
    /// Should be called at app startup to trigger the macOS permission dialog.
    /// Does not set `.denied` on failure — the browser error paths handle that
    /// once the user has had a chance to respond to the system prompt.
    func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        )
        if trusted {
            logger.info("Accessibility permission already granted")
            Task { @MainActor in
                self.accessibilityPermissionStatus = .granted
            }
        } else {
            logger.warning("Accessibility permission not granted — user prompted")
        }
    }

    /// Proactively triggers macOS permission dialogs for Automation and Accessibility.
    /// Sends a benign AppleScript to System Events to force the TCC Automation dialog
    /// to appear. Also prompts for Accessibility if not yet granted.
    ///
    /// Should be called once at app startup. On first launch, this will cause macOS
    /// to show "Kairos wants to control System Events" and prompt for Accessibility access.
    func requestPermissions() {
        checkAccessibilityPermission()
        triggerSystemEventsAutomationPermissionCheck()
        requestBrowserAutomationPermissionsForRunningBrowsers()
    }

    /// Sends a lightweight AppleScript to System Events to trigger the Automation TCC dialog.
    /// This is the only way to force macOS to show the "Kairos wants to control System Events"
    /// permission prompt — there is no explicit API to request Automation permission.
    ///
    /// After System Events permission is granted, individual browser Automation dialogs
    /// will appear automatically when their AppleScripts are first executed.
    private func triggerSystemEventsAutomationPermissionCheck() {
        let script = """
            tell application "System Events" to return "ok"
            """

        guard let appleScript = NSAppleScript(source: script) else {
            logger.error("Failed to create Automation permission check script")
            return
        }

        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)

        if let error = error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            if code == -1743 || code == -1744 {
                logger.warning("System Events Automation permission denied or not yet granted (code: \(code))")
                Task { @MainActor in
                    self.systemEventsPermissionStatus = .denied
                }
            } else {
                logger.warning("System Events permission check failed with code: \(code)")
            }
        } else {
            logger.info("System Events permission check succeeded")
            Task { @MainActor in
                self.systemEventsPermissionStatus = .granted
            }
        }
    }

    /// Sends lightweight Apple Events to supported browsers that are already running.
    /// Automation entries only appear in System Settings after the app has actually
    /// contacted each target app at least once.
    func requestBrowserAutomationPermissionsForRunningBrowsers() {
        let runningBrowserBundleIds = NSWorkspace.shared.runningApplications
            .compactMap(\.bundleIdentifier)
            .filter { AppConstants.AnalyticsSettings.supportedBrowsers[$0] != nil }

        let uniqueBrowserBundleIds = Array(Set(runningBrowserBundleIds)).sorted {
            let lhsName = AppConstants.AnalyticsSettings.supportedBrowsers[$0] ?? $0
            let rhsName = AppConstants.AnalyticsSettings.supportedBrowsers[$1] ?? $1
            return lhsName < rhsName
        }

        guard !uniqueBrowserBundleIds.isEmpty else {
            logger.info("No supported browsers are running; browser Automation prompt deferred")
            return
        }

        for bundleId in uniqueBrowserBundleIds {
            let browserName = AppConstants.AnalyticsSettings.supportedBrowsers[bundleId] ?? bundleId
            triggerBrowserAutomationPermissionCheck(bundleId: bundleId, browserName: browserName)
        }
    }

    private func triggerBrowserAutomationPermissionCheck(bundleId: String, browserName: String) {
        let script = """
            tell application id "\(bundleId)" to return name
            """

        guard let appleScript = NSAppleScript(source: script) else {
            logger.error("Failed to create browser Automation permission check script for \(browserName, privacy: .public)")
            return
        }

        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)

        if let error = error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            if code == -1743 || code == -1744 {
                handleBrowserPermissionResult(success: false, browserName: browserName)
            } else if code == -1712 {
                logger.debug("\(browserName, privacy: .public) Automation permission check timed out")
            } else {
                logger.warning(
                    "\(browserName, privacy: .public) Automation permission check failed with code: \(code)")
            }
            return
        }

        if result.stringValue != nil {
            handleBrowserPermissionResult(success: true, browserName: browserName)
        }
    }

    /// Opens System Preferences to the Automation privacy settings.
    /// Allows users to grant AppleScript permissions for browser automation and System Events access.
    func openSystemPreferences() {
        triggerSystemEventsAutomationPermissionCheck()
        requestBrowserAutomationPermissionsForRunningBrowsers()

        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
        NSWorkspace.shared.open(url)
        logger.info("Opening System Settings > Privacy & Security > Automation")
    }

    /// Opens System Preferences to the Accessibility privacy settings.
    /// Allows users to grant Accessibility permissions for Safari private browsing detection.
    func openAccessibilityPreferences() {
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        logger.info("Opening System Settings > Privacy & Security > Accessibility")
    }

    /// Records browser communication errors for UI display.
    /// - Parameter errorMessage: Description of the browser communication error
    func handleBrowserError(_ errorMessage: String) {
        Task { @MainActor in
            self.lastError = errorMessage
        }
    }

    /// Clears the current error message from the UI state.
    func clearError() {
        Task { @MainActor in
            self.lastError = nil
        }
    }
}

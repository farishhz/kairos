//
//  BrowserActivityResolverTests.swift
//  KairosTest
//
//  Unit Testing Bundle
//  Tests for BrowserActivityResolver browser detection and constants
//

import Foundation
import Testing
@testable import Kairos

struct BrowserActivityResolverTests {
    let resolver = BrowserActivityResolver.shared

    // MARK: - Browser Support

    @Test func supportedBrowsersReturnTrue() {
        let supported = [
            "com.apple.Safari",
            "com.google.Chrome",
            "com.microsoft.edgemac",
            "com.brave.Browser",
            "com.operasoftware.Opera",
            "company.com.Arc",
            "com.vivaldi.Vivaldi",
            "org.mozilla.firefox",
        ]
        for bundleId in supported {
            #expect(resolver.isBrowserSupported(bundleId) == true, "Expected \(bundleId) to be supported")
        }
    }

    @Test func unsupportedBrowserReturnsFalse() {
        #expect(resolver.isBrowserSupported("com.apple.Terminal") == false)
        #expect(resolver.isBrowserSupported("com.apple.TextEdit") == false)
        #expect(resolver.isBrowserSupported("") == false)
    }

    // MARK: - resolveCurrentTab with unsupported browser

    @Test func resolveCurrentTabUnsupportedBrowserReturnsNil() {
        let result = resolver.resolveCurrentTab(for: "com.apple.Terminal")
        #expect(result == nil)
    }

    // MARK: - Supported Browser Bundle IDs Match Constants

    @Test func supportedBrowserBundleIdsMatchConstants() {
        let supported = AppConstants.AnalyticsSettings.supportedBrowsers
        #expect(supported.count == 8)
        #expect(supported["com.apple.Safari"] == "Safari")
        #expect(supported["com.google.Chrome"] == "Google Chrome")
        #expect(supported["org.mozilla.firefox"] == "Firefox")
    }

    // MARK: - Excluded Bundle IDs

    @Test func excludedBundleIdsAreSystemApps() {
        let excluded = AppConstants.AnalyticsSettings.excludedBundleIds
        #expect(excluded.contains("com.apple.dock"))
        #expect(excluded.contains("com.apple.loginwindow"))
        #expect(excluded.contains("com.apple.Spotlight"))
        #expect(excluded.contains("com.apple.notificationcenterui"))
        #expect(excluded.contains("com.apple.controlcenter"))
        #expect(excluded.contains("com.apple.WindowManager"))
        #expect(excluded.contains("com.apple.SystemUIServer"))
    }

    // MARK: - Polling Constants

    @Test func pollingConstantsAreReasonable() {
        #expect(AppConstants.AnalyticsSettings.pollingInterval == 1.0)
        #expect(AppConstants.AnalyticsSettings.idleThreshold == 300.0)
        #expect(AppConstants.AnalyticsSettings.websitePollCooldown == 5.0)
        #expect(AppConstants.AnalyticsSettings.websitePollGracePeriod == 8.0)
        #expect(AppConstants.AnalyticsSettings.websitePollMaxConcurrent == 2)
        #expect(AppConstants.AnalyticsSettings.websitePollFailureThreshold == 3)
    }
}

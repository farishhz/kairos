import Foundation
import AppKit
import OSLog

final class BrowserActivityResolver {
    static let shared = BrowserActivityResolver()

    private let browsers: [String: BrowserInterface]
    private var cooldownUntil: Date?
    private var consecutiveFailures = 0

    private init() {
        let browserList: [BrowserInterface] = [
            SafariBrowser(),
            ChromeBrowser(),
            EdgeBrowser(),
            BraveBrowser(),
            OperaBrowser(),
            ArcBrowser(),
            VivaldiBrowser(),
            FirefoxBrowser(),
        ]
        self.browsers = Dictionary(uniqueKeysWithValues: browserList.map { ($0.bundleId, $0) })
    }

    func isBrowserSupported(_ bundleId: String) -> Bool {
        browsers[bundleId] != nil
    }

    func resolveCurrentTab(for bundleId: String) -> (domain: String, url: String?, title: String?)? {
        guard let browser = browsers[bundleId] else {
            return nil
        }

        if let cooldownUntil, Date() < cooldownUntil {
            return nil
        }

        guard let urlString = browser.getCurrentURL() else {
            consecutiveFailures += 1
            if consecutiveFailures >= AppConstants.AnalyticsSettings.websitePollFailureThreshold {
                cooldownUntil = Date().addingTimeInterval(AppConstants.AnalyticsSettings.websitePollCooldown)
                consecutiveFailures = 0
                let threshold = AppConstants.AnalyticsSettings.websitePollFailureThreshold
                Logger.browser.warning("Cooldown triggered after \(threshold) failures")
            }
            return nil
        }

        consecutiveFailures = 0
        cooldownUntil = nil

        guard let url = URL(string: urlString), let host = url.host else {
            return nil
        }

        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return (domain: domain, url: urlString, title: nil)
    }
}

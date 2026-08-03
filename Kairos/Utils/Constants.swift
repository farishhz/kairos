import Foundation

enum AppConstants {
    enum QuickPresets {
        static let preset1Key = "quickPreset1"
        static let preset2Key = "quickPreset2"
        static let preset3Key = "quickPreset3"
        static let defaultValues: [Int] = [5, 10, 25]
        static let minMinutes: Int = 1
        static let maxMinutes: Int = 60
    }

    enum SoundSettings {
        static let selectedSoundKey = "selectedSoundID"
        static let autoMuteAfter5SecondsKey = "autoMuteAfter5Seconds"
        static let volumeKey = "soundVolume"

        static let defaultSoundID = "alarm-1"
        static let defaultVolume = 0.6
        static let minVolume = 0.0
        static let maxVolume = 1.0
        static let options: [SoundOption] = [
            SoundOption(id: "alarm-1", title: "Alarm 1", fileName: "alarm-1", fileExtension: "m4a"),
            SoundOption(id: "alarm-2", title: "Alarm 2", fileName: "alarm-2", fileExtension: "m4a"),
            SoundOption(id: "alarm-3", title: "Alarm 3", fileName: "alarm-3", fileExtension: "m4a"),
        ]
    }

    enum FloatingThemeSettings {
        static let opacityKey = "floatingOpacity"
        static let selectedThemeKey = "floatingThemeID"
        static let defaultThemeID = "obsidian"
        static let defaultOpacity = 0.85
        static let minOpacity = 0.4
        static let maxOpacity = 1.0
    }

    enum FloatingLayoutSettings {
        static let timerOnlyWidth: CGFloat = 110
        static let timerOnlyHeight: CGFloat = 62
        static let timerOnlyFontSize: CGFloat = 30
    }

    enum BreakDuration {
        static let shortMinutes: Int = 5
        static let longMinutes: Int = 15
    }

    enum MenuBarSettings {
        static let compactIconKey = "menuBarCompactIcon"
        static let selectedPresetMinutesKey = "menuBarSelectedPresetMinutes"
        static let defaultPresetMinutes = 25
        static let panelWidth: CGFloat = 250
        static let panelHeight: CGFloat = 138
    }

enum AnalyticsSettings {
        static let focusSessionsFile = "focus-sessions.json"
        static let appActivityFile = "app-activity.json"
        static let websiteVisitsFile = "website-visits.json"
        static let analyticsDirectoryName = "Analytics"
        static let retentionDays = 180
        static let analyticsEnabledKey = "analyticsEnabled"
        static let defaultAnalyticsEnabled = true
        static let defaultDashboardRangeDays = 30
        static let heatmapDays = 30
        static let weeklySummaryDays = 7

        static let supportedBrowsers: [String: String] = [
            "com.apple.Safari": "Safari",
            "com.google.Chrome": "Google Chrome",
            "org.mozilla.firefox": "Firefox",
            "com.microsoft.edgemac": "Microsoft Edge",
            "com.brave.Browser": "Brave Browser",
            "com.operasoftware.Opera": "Opera",
            "company.thebrowser.Browser": "Arc",
            "com.vivaldi.Vivaldi": "Vivaldi",
        ]

        static let knownFloatingApps: Set<String> = [
            "com.1password.1password",
            "com.1password.7",
            "com.ghostty",
            "com.runningwithcrayons.Alfred",
            "com.raycast.macos",
            "com.macpaw.CleanMyMac-setapp",
            "com.macpaw.CleanMyMac4",
            "com.figma.Desktop",
            "com.tinyspeck.slackmacgap",
        ]

        static let excludedBundleIds: Set<String> = [
            "com.apple.dock",
            "com.apple.loginwindow",
            "com.apple.Spotlight",
            "com.apple.notificationcenterui",
            "com.apple.controlcenter",
            "com.apple.WindowManager",
            "com.apple.SystemUIServer",
        ]

        static let pollingInterval: TimeInterval = 1.0
        static let idleThreshold: TimeInterval = 300.0

        static let websitePollCooldown: TimeInterval = 5.0
        static let websitePollGracePeriod: TimeInterval = 8.0
        static let websitePollMaxConcurrent = 2
        static let websitePollFailureThreshold = 3

        static var analyticsDirectoryURL: URL {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            return appSupport.appendingPathComponent("Kairos").appendingPathComponent(analyticsDirectoryName)
        }

        static var isAnalyticsEnabled: Bool {
            get {
                let defaults = UserDefaults.standard
                guard defaults.object(forKey: analyticsEnabledKey) != nil else {
                    return defaultAnalyticsEnabled
                }
                return defaults.bool(forKey: analyticsEnabledKey)
            }
            set { UserDefaults.standard.set(newValue, forKey: analyticsEnabledKey) }
        }
    }
}

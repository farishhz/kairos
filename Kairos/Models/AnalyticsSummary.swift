import Foundation

struct AnalyticsSummary: Codable, Hashable {
    var todayFocusSeconds: Double
    var weekFocusSeconds: Double
    var streakDays: Int
    var bestDay: Date?
    var bestDaySeconds: Double
    var topApps: [AnalyticsBreakdownItem]
    var topDomains: [AnalyticsBreakdownItem]

    init(
        todayFocusSeconds: Double = 0,
        weekFocusSeconds: Double = 0,
        streakDays: Int = 0,
        bestDay: Date? = nil,
        bestDaySeconds: Double = 0,
        topApps: [AnalyticsBreakdownItem] = [],
        topDomains: [AnalyticsBreakdownItem] = []
    ) {
        self.todayFocusSeconds = todayFocusSeconds
        self.weekFocusSeconds = weekFocusSeconds
        self.streakDays = streakDays
        self.bestDay = bestDay
        self.bestDaySeconds = bestDaySeconds
        self.topApps = topApps
        self.topDomains = topDomains
    }

    var hasData: Bool {
        todayFocusSeconds > 0 || weekFocusSeconds > 0 || !topApps.isEmpty || !topDomains.isEmpty
    }
}

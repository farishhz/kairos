import Foundation

struct DailyAnalyticsSnapshot: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var focusSeconds: Double
    var sessionCount: Int
    var topApps: [TopItem]
    var topDomains: [TopItem]
    var heatmapScore: Int

    struct TopItem: Codable, Hashable {
        var name: String
        var seconds: Double
    }

    init(
        id: UUID = UUID(),
        date: Date,
        focusSeconds: Double = 0,
        sessionCount: Int = 0,
        topApps: [TopItem] = [],
        topDomains: [TopItem] = [],
        heatmapScore: Int = 0
    ) {
        self.id = id
        self.date = date
        self.focusSeconds = focusSeconds
        self.sessionCount = sessionCount
        self.topApps = topApps
        self.topDomains = topDomains
        self.heatmapScore = heatmapScore
    }

    var id_date: Date { date }

    static func == (lhs: DailyAnalyticsSnapshot, rhs: DailyAnalyticsSnapshot) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

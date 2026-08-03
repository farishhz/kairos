import Foundation

enum AnalyticsPreviewFactory {
    static func makeEmptySummary() -> AnalyticsSummary {
        AnalyticsSummary()
    }

    static func makePopulatedSummary() -> AnalyticsSummary {
        AnalyticsSummary(
            todayFocusSeconds: 5400,
            weekFocusSeconds: 18000,
            streakDays: 5,
            bestDay: Date().addingTimeInterval(-86400 * 2),
            bestDaySeconds: 7200,
            topApps: [
                AnalyticsBreakdownItem(name: "Xcode", seconds: 3600, icon: nil, percentage: 66.7),
                AnalyticsBreakdownItem(name: "Safari", seconds: 1200, icon: nil, percentage: 22.2),
                AnalyticsBreakdownItem(name: "Finder", seconds: 600, icon: nil, percentage: 11.1),
            ],
            topDomains: [
                AnalyticsBreakdownItem(name: "github.com", seconds: 1800, icon: nil, percentage: 60),
                AnalyticsBreakdownItem(name: "stackoverflow.com", seconds: 900, icon: nil, percentage: 30),
                AnalyticsBreakdownItem(name: "developer.apple.com", seconds: 300, icon: nil, percentage: 10),
            ]
        )
    }

    static func makeHeatmapCells(days: Int = 30) -> [AnalyticsHeatmapCell] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today)!

        var cells: [AnalyticsHeatmapCell] = []
        var currentDate = startDate
        while currentDate <= today {
            let weekday = calendar.component(.weekday, from: currentDate)
            let isWeekend = weekday == 1 || weekday == 7
            let randomSeconds = isWeekend ? Double.random(in: 0...600) : Double.random(in: 600...7200)
            let sessionCount = randomSeconds > 0 ? Int.random(in: 1...4) : 0
            let level = intensityLevel(for: randomSeconds)
            cells.append(
                AnalyticsHeatmapCell(
                    date: currentDate,
                    focusSeconds: randomSeconds,
                    sessionCount: sessionCount,
                    intensityLevel: level))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return cells
    }

    static func makeTimelineEntries() -> [AnalyticsTimelineEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let h9 = calendar.date(byAdding: .hour, value: 9, to: today)!
        let h10 = calendar.date(byAdding: .hour, value: 10, to: today)!
        let h11 = calendar.date(byAdding: .hour, value: 11, to: today)!
        let h13 = calendar.date(byAdding: .hour, value: 13, to: today)!
        return [
            AnalyticsTimelineEntry(
                startedAt: h9,
                endedAt: calendar.date(byAdding: .minute, value: 45, to: h9)!,
                kind: .app,
                name: "Xcode",
                detail: "Project Kairos",
                seconds: 2700),
            AnalyticsTimelineEntry(
                startedAt: h10,
                endedAt: calendar.date(byAdding: .minute, value: 20, to: h10)!,
                kind: .website,
                name: "github.com",
                detail: "Pull Requests",
                seconds: 1200),
            AnalyticsTimelineEntry(
                startedAt: h11,
                endedAt: calendar.date(byAdding: .minute, value: 30, to: h11)!,
                kind: .app,
                name: "Safari",
                detail: "Reading docs",
                seconds: 1800),
            AnalyticsTimelineEntry(
                startedAt: h13,
                endedAt: calendar.date(byAdding: .minute, value: 15, to: h13)!,
                kind: .website,
                name: "stackoverflow.com",
                detail: "Swift question",
                seconds: 900),
        ]
    }

    static func makeBreakdownItems() -> [AnalyticsBreakdownItem] {
        [
            AnalyticsBreakdownItem(name: "Xcode", seconds: 7200, icon: nil, percentage: 48),
            AnalyticsBreakdownItem(name: "Safari", seconds: 3600, icon: nil, percentage: 24),
            AnalyticsBreakdownItem(name: "Finder", seconds: 1800, icon: nil, percentage: 12),
            AnalyticsBreakdownItem(name: "Terminal", seconds: 1200, icon: nil, percentage: 8),
            AnalyticsBreakdownItem(name: "Notes", seconds: 1200, icon: nil, percentage: 8),
        ]
    }

    private static func intensityLevel(for seconds: Double) -> Int {
        let minutes = seconds / 60.0
        if minutes == 0 { return 0 }
        if minutes < 15 { return 1 }
        if minutes < 30 { return 2 }
        if minutes < 60 { return 3 }
        if minutes < 120 { return 4 }
        return 5
    }
}

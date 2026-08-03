import Foundation

final class AnalyticsEngine {
    static let shared = AnalyticsEngine()

    private init() {}

    // MARK: - Summary

    func buildSummary(
        from sessions: [FocusSessionRecord],
        appEvents: [AppActivityEvent],
        webVisits: [WebsiteVisitRecord]) -> AnalyticsSummary
    {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(
            byAdding: .day,
            value: -(AppConstants.AnalyticsSettings.weeklySummaryDays - 1),
            to: today)!

        let todaySessions = sessions.filter { calendar.startOfDay(for: $0.startedAt) == today }
        let weekSessions = sessions.filter { $0.startedAt >= weekStart }

        let todayFocus = todaySessions.reduce(0) { $0 + $1.actualFocusSeconds }
        let weekFocus = weekSessions.reduce(0) { $0 + $1.actualFocusSeconds }

        let streak = Self.calculateStreak(from: sessions)
        let (bestDay, bestDaySeconds) = Self.calculateBestDay(from: sessions)

        return AnalyticsSummary(
            todayFocusSeconds: todayFocus,
            weekFocusSeconds: weekFocus,
            streakDays: streak,
            bestDay: bestDay,
            bestDaySeconds: bestDaySeconds,
            topApps: self.buildTopApps(from: appEvents),
            topDomains: self.buildTopDomains(from: webVisits)
        )
    }

    // MARK: - Heatmap

    func buildHeatmapCells(
        from sessions: [FocusSessionRecord],
        days: Int = 210) -> [AnalyticsHeatmapCell]
    {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetStart = calendar.date(byAdding: .day, value: -(days - 1), to: today)!

        let weekday = calendar.component(.weekday, from: targetStart)
        let daysToSunday = weekday - 1
        let actualStart = calendar.date(byAdding: .day, value: -daysToSunday, to: targetStart)!

        var dayTotals: [Date: Double] = [:]
        var daySessionCounts: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.startedAt)
            if day >= actualStart && day <= today {
                dayTotals[day, default: 0] += session.actualFocusSeconds
                daySessionCounts[day, default: 0] += 1
            }
        }

        var cells: [AnalyticsHeatmapCell] = []
        var currentDate = actualStart
        while currentDate <= today {
            let seconds = dayTotals[currentDate] ?? 0
            let sessionCount = daySessionCounts[currentDate] ?? 0
            let level = Self.intensityLevel(for: seconds)
            cells.append(
                AnalyticsHeatmapCell(
                    date: currentDate,
                    focusSeconds: seconds,
                    sessionCount: sessionCount,
                    intensityLevel: level))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return cells
    }

    // MARK: - Daily Snapshots

    func buildDailySnapshots(
        from sessions: [FocusSessionRecord],
        appEvents: [AppActivityEvent],
        webVisits: [WebsiteVisitRecord],
        days: Int = AppConstants.AnalyticsSettings.defaultDashboardRangeDays) -> [DailyAnalyticsSnapshot]
    {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today)!

        var daySessions: [Date: [FocusSessionRecord]] = [:]
        for session in sessions where session.startedAt >= startDate {
            let day = calendar.startOfDay(for: session.startedAt)
            daySessions[day, default: []].append(session)
        }

        var dayAppEvents: [Date: [AppActivityEvent]] = [:]
        for event in appEvents where event.startedAt >= startDate {
            let day = calendar.startOfDay(for: event.startedAt)
            dayAppEvents[day, default: []].append(event)
        }

        var dayWebVisits: [Date: [WebsiteVisitRecord]] = [:]
        for visit in webVisits where visit.startedAt >= startDate {
            let day = calendar.startOfDay(for: visit.startedAt)
            dayWebVisits[day, default: []].append(visit)
        }

        var snapshots: [DailyAnalyticsSnapshot] = []
        var currentDate = startDate
        while currentDate <= today {
            let sessions = daySessions[currentDate] ?? []
            let focusSeconds = sessions.reduce(0) { $0 + $1.actualFocusSeconds }

            let apps = (dayAppEvents[currentDate] ?? [])
            let appGroups = Dictionary(grouping: apps, by: { $0.appName })
            let topApps = appGroups
                .map { name, events in
                    DailyAnalyticsSnapshot.TopItem(
                        name: name,
                        seconds: events.reduce(0) { $0 + $1.durationSeconds })
                }
                .sorted { $0.seconds > $1.seconds }
                .prefix(5)

            let visits = (dayWebVisits[currentDate] ?? [])
            let domainGroups = Dictionary(grouping: visits, by: { $0.domain })
            let topDomains = domainGroups
                .map { domain, v in
                    DailyAnalyticsSnapshot.TopItem(
                        name: domain,
                        seconds: v.reduce(0) { $0 + $1.durationSeconds })
                }
                .sorted { $0.seconds > $1.seconds }
                .prefix(5)

            snapshots.append(DailyAnalyticsSnapshot(
                date: currentDate,
                focusSeconds: focusSeconds,
                sessionCount: sessions.count,
                topApps: Array(topApps),
                topDomains: Array(topDomains),
                heatmapScore: Self.intensityLevel(for: focusSeconds)
            ))

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return snapshots
    }

    // MARK: - Timeline

    func buildTimeline(
        for date: Date,
        appEvents: [AppActivityEvent],
        webVisits: [WebsiteVisitRecord]) -> [AnalyticsTimelineEntry]
    {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let dayApps = appEvents
            .filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
            .sorted { $0.startedAt < $1.startedAt }

        let dayWeb = webVisits
            .filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
            .sorted { $0.startedAt < $1.startedAt }

        var entries: [AnalyticsTimelineEntry] = []

        for event in dayApps {
            let ended = event.endedAt ?? event.startedAt
            entries.append(AnalyticsTimelineEntry(
                startedAt: event.startedAt,
                endedAt: ended,
                kind: .app,
                name: event.appName,
                detail: event.windowTitle,
                seconds: event.durationSeconds
            ))
        }

        for visit in dayWeb {
            let ended = visit.endedAt ?? visit.startedAt
            entries.append(AnalyticsTimelineEntry(
                startedAt: visit.startedAt,
                endedAt: ended,
                kind: .website,
                name: visit.domain,
                detail: visit.pageTitle,
                seconds: visit.durationSeconds
            ))
        }

        return entries.sorted { $0.startedAt < $1.startedAt }
    }

    // MARK: - Breakdown

    func buildTopApps(
        from appEvents: [AppActivityEvent],
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int = 10) -> [AnalyticsBreakdownItem]
    {
        let filteredEvents = appEvents.filter { event in
            Self.isWithinRange(event.startedAt, startDate: startDate, endDate: endDate)
        }

        return self.buildBreakdownItems(
            from: filteredEvents,
            groupKey: \.appName,
            duration: \.durationSeconds,
            bundleIdKey: \.appBundleID,
            limit: limit)
    }

    func buildTopDomains(
        from webVisits: [WebsiteVisitRecord],
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int = 10) -> [AnalyticsBreakdownItem]
    {
        let filteredVisits = webVisits.filter { visit in
            Self.isWithinRange(visit.startedAt, startDate: startDate, endDate: endDate)
        }

        return self.buildBreakdownItems(
            from: filteredVisits,
            groupKey: \.domain,
            duration: \.durationSeconds,
            bundleIdKey: nil,
            limit: limit,
            isWebsite: true)
    }

    // MARK: - Helpers

    nonisolated static func calculateStreak(from sessions: [FocusSessionRecord]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let uniqueDays = Set(
            sessions
                .filter { $0.actualFocusSeconds > 0 }
                .map { calendar.startOfDay(for: $0.startedAt) })

        var streak = 0
        var currentDay = today

        while uniqueDays.contains(currentDay) {
            streak += 1
            currentDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
        }

        if streak == 0 && uniqueDays.contains(calendar.date(byAdding: .day, value: -1, to: today)!) {
            currentDay = calendar.date(byAdding: .day, value: -1, to: today)!
            while uniqueDays.contains(currentDay) {
                streak += 1
                currentDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
            }
        }

        return streak
    }

    nonisolated static func calculateBestDay(from sessions: [FocusSessionRecord]) -> (Date?, Double) {
        let calendar = Calendar.current
        var dayTotals: [Date: Double] = [:]
        for session in sessions where session.actualFocusSeconds > 0 {
            let day = calendar.startOfDay(for: session.startedAt)
            dayTotals[day, default: 0] += session.actualFocusSeconds
        }
        guard let bestEntry = dayTotals.max(by: { $0.value < $1.value }) else {
            return (nil, 0)
        }
        return (bestEntry.key, bestEntry.value)
    }

    nonisolated static func intensityLevel(for seconds: Double) -> Int {
        let minutes = seconds / 60.0
        if minutes == 0 { return 0 }
        if minutes < 15 { return 1 }
        if minutes < 30 { return 2 }
        if minutes < 60 { return 3 }
        if minutes < 120 { return 4 }
        return 5
    }

    nonisolated static func startOfWeek(for date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    nonisolated static func endOfWeek(for date: Date, calendar: Calendar) -> Date {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
            return calendar.startOfDay(for: date)
        }
        return calendar.date(byAdding: .day, value: 6, to: weekStart) ?? calendar.startOfDay(for: date)
    }

    nonisolated static func isWithinRange(_ date: Date, startDate: Date?, endDate: Date?) -> Bool {
        if let startDate, date < startDate {
            return false
        }
        if let endDate, date >= endDate {
            return false
        }
        return true
    }

    private func buildBreakdownItems<T>(
        from items: [T],
        groupKey: KeyPath<T, String>,
        duration: KeyPath<T, Double>,
        bundleIdKey: KeyPath<T, String>?,
        limit: Int,
        isWebsite: Bool = false) -> [AnalyticsBreakdownItem]
    {
        let totalSeconds = items.reduce(0) { $0 + $1[keyPath: duration] }
        let groups = Dictionary(grouping: items, by: { $0[keyPath: groupKey] })

        return groups
            .map { name, groupedItems in
                let bundleID: String? = bundleIdKey.flatMap { key in
                    groupedItems.first?[keyPath: key]
                }

                var iconData: Data?
                if isWebsite {
                    // For websites, try to get a favicon asynchronously later,
                    // but for now return nil so the view shows the letter fallback.
                    // A real favicon fetch can be done in the view layer or pre-warmed.
                    iconData = nil
                } else {
                    iconData = bundleID.flatMap { IconUtils.getAppIconAsPNG(for: $0) }
                }

                return AnalyticsBreakdownItem(
                    name: name,
                    seconds: groupedItems.reduce(0) { $0 + $1[keyPath: duration] },
                    icon: nil,
                    bundleID: bundleID,
                    iconData: iconData,
                    isWebsite: isWebsite)
            }
            .sorted { $0.seconds > $1.seconds }
            .prefix(limit)
            .map { item in
                var copy = item
                copy.percentage = totalSeconds > 0 ? (item.seconds / totalSeconds) * 100 : 0
                return copy
            }
    }
}

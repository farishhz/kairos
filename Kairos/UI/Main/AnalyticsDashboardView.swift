import AppKit
import SwiftUI

struct AnalyticsDashboardView: View {
    private let usePreviewData: Bool

    @State private var dashboardState: DashboardState = .loading
    @State private var selectedDay = Calendar.current.startOfDay(for: Date())

    init(usePreviewData: Bool = false) {
        self.usePreviewData = usePreviewData
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsPageHeader(
                    title: "Analytics",
                    subtitle: "Inspect focus history, daily sessions, and tracked activity.")

                self.content
            }
            .padding(24)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            self.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            self.loadData()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch self.dashboardState {
        case .loading:
            SettingsSurfaceCard {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Loading analytics...")
                        .font(.kairosSubheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .empty(let emptyState):
            self.emptyStateView(emptyState)
        case .loaded(let data):
            AnalyticsHeatmapView(cells: data.heatmapCells, selectedDate: self.$selectedDay)
            self.dayOverviewView(data: data)
            // AnalyticsActiveTimeCard — deferred to next update
            // AnalyticsActiveTimeCard(
            //     selectedDate: self.selectedDay,
            //     workPeriods: self.selectedDayWorkPeriods(in: data),
            //     totalActiveTime: self.selectedDayTotalActiveTime(in: data),
            //     topApps: self.selectedDayApps(in: data),
            //     topWebsites: self.selectedDayDomains(in: data))
            // Session Summaries - deferred to next release
            // self.sessionSummariesView(data: data)
            AnalyticsBreakdownView(
                date: self.selectedDay,
                apps: self.selectedDayApps(in: data),
                domains: self.selectedDayDomains(in: data))
        }
    }

    @ViewBuilder
    private func emptyStateView(_ emptyState: DashboardEmptyState) -> some View {
        switch emptyState {
        case .noData:
            AnalyticsEmptyStateView()
        case .noSessions:
            AnalyticsEmptyStateView(
                icon: "hourglass",
                message: "No focus sessions yet",
                subtitle: "Start your first focus session to unlock heatmap, summaries, and daily breakdown.")
        }
    }

    @ViewBuilder
    private func dayOverviewView(data: AnalyticsDashboardData) -> some View {
        let sessions = self.selectedDaySessions(in: data)
        let totalFocusSeconds = sessions.reduce(0) { $0 + $1.actualFocusSeconds }
        let completedCount = sessions.filter { $0.completed }.count
        let interruptedCount = sessions.filter { !$0.completed }.count

        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Day Overview",
                    subtitle: "Focus summary for \(Self.selectedDayFormatter.string(from: self.selectedDay)).")

                if sessions.isEmpty {
                    Text("No sessions recorded for this day.")
                        .font(.kairosSubheadline)
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 16) {
                        OverviewStatCard(
                            title: "Total Focus",
                            value: Self.formatDuration(totalFocusSeconds),
                            icon: "clock.fill",
                            color: .blue)

                        OverviewStatCard(
                            title: "Sessions",
                            value: "\(sessions.count)",
                            icon: "repeat.circle.fill",
                            color: .purple)

                        OverviewStatCard(
                            title: "Completed",
                            value: "\(completedCount)",
                            icon: "checkmark.circle.fill",
                            color: .green)

                        OverviewStatCard(
                            title: "Interrupted",
                            value: "\(interruptedCount)",
                            icon: "xmark.circle.fill",
                            color: .orange)
                    }
                }
            }
        }
    }

    // Session Summaries - deferred to next release
    /*
    @ViewBuilder
    private func sessionSummariesView(data: AnalyticsDashboardData) -> some View {
        let sessions = self.selectedDaySessions(in: data)

        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionHeading(
                    title: "Session Summaries",
                    subtitle: "Pomodoro sessions for \(Self.selectedDayFormatter.string(from: self.selectedDay)).")

                if sessions.isEmpty {
                    Text("No focus sessions on this day.")
                        .font(.kairosSubheadline)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(sessions) { session in
                            AnalyticsSessionSummaryCard(
                                session: session,
                                appHighlights: self.topApps(for: session, in: data),
                                websiteHighlights: self.topDomains(for: session, in: data))
                        }
                    }
                }
            }
        }
    }
    */

    private func loadData() {
        let data = self.usePreviewData ? self.makePreviewData() : self.makeStoredData()

        guard let data else {
            self.dashboardState = .empty(.noData)
            return
        }

        self.syncSelectedDay(using: data)

        if data.hasVisibleData {
            self.dashboardState = .loaded(data)
        } else if data.sessions.isEmpty {
            self.dashboardState = .empty(.noSessions)
        } else {
            self.dashboardState = .empty(.noData)
        }
    }

    private func makeStoredData() -> AnalyticsDashboardData? {
        let sessions = AnalyticsStore.shared.loadFocusSessions()
        let appEvents = AnalyticsStore.shared.loadAppActivityEvents()
        let webVisits = AnalyticsStore.shared.loadWebsiteVisits()
        let heatmapCells = AnalyticsEngine.shared.buildHeatmapCells(from: sessions)

        return AnalyticsDashboardData(
            sessions: sessions,
            appEvents: appEvents,
            webVisits: webVisits,
            heatmapCells: heatmapCells)
    }

    private func makePreviewData() -> AnalyticsDashboardData {
        let sessions = self.previewSessions()
        let appEvents = self.previewAppEvents(sessions: sessions)
        let webVisits = self.previewWebsiteVisits(sessions: sessions)
        let heatmapCells = AnalyticsEngine.shared.buildHeatmapCells(from: sessions)

        return AnalyticsDashboardData(
            sessions: sessions,
            appEvents: appEvents,
            webVisits: webVisits,
            heatmapCells: heatmapCells)
    }

    private func syncSelectedDay(using data: AnalyticsDashboardData) {
        let availableDays = Set(data.heatmapCells.map(\.date))
        if availableDays.contains(where: { Calendar.current.isDate($0, inSameDayAs: self.selectedDay) }) {
            return
        }

        if let latestFocusDay = data.latestFocusDate {
            self.selectedDay = latestFocusDay
        } else if let latestVisibleDay = data.heatmapCells.last?.date {
            self.selectedDay = latestVisibleDay
        } else {
            self.selectedDay = Calendar.current.startOfDay(for: Date())
        }
    }

    private func selectedDaySessions(in data: AnalyticsDashboardData) -> [FocusSessionRecord] {
        data.sessions
            .filter { Calendar.current.isDate($0.startedAt, inSameDayAs: self.selectedDay) }
            .sorted { $0.startedAt < $1.startedAt }
    }

    private func selectedDayApps(in data: AnalyticsDashboardData) -> [AnalyticsBreakdownItem] {
        let range = self.selectedDayRange
        return AnalyticsEngine.shared.buildTopApps(
            from: data.appEvents,
            startDate: range.start,
            endDate: range.end,
            limit: 5)
    }

    private func selectedDayDomains(in data: AnalyticsDashboardData) -> [AnalyticsBreakdownItem] {
        let range = self.selectedDayRange
        return AnalyticsEngine.shared.buildTopDomains(
            from: data.webVisits,
            startDate: range.start,
            endDate: range.end,
            limit: 5)
    }

    private func selectedDayTimeline(in data: AnalyticsDashboardData) -> [AnalyticsTimelineEntry] {
        AnalyticsEngine.shared.buildTimeline(
            for: self.selectedDay,
            appEvents: data.appEvents,
            webVisits: data.webVisits)
    }

    private func selectedDayWorkPeriods(
        in data: AnalyticsDashboardData
    ) -> [(startTime: Date, endTime: Date, duration: TimeInterval)] {
        let sessions = self.selectedDaySessions(in: data)
        let completedSessions = sessions.compactMap { session -> (Date, Date)? in
            guard let endTime = session.endedAt else { return nil }
            return (session.startedAt, endTime)
        }.sorted { $0.0 < $1.0 }

        guard !completedSessions.isEmpty else { return [] }

        var mergedPeriods: [(Date, Date)] = []
        var currentStart = completedSessions[0].0
        var currentEnd = completedSessions[0].1

        for (sessionStart, sessionEnd) in completedSessions.dropFirst() {
            if sessionStart <= currentEnd {
                currentEnd = max(currentEnd, sessionEnd)
            } else {
                mergedPeriods.append((currentStart, currentEnd))
                currentStart = sessionStart
                currentEnd = sessionEnd
            }
        }
        mergedPeriods.append((currentStart, currentEnd))

        return mergedPeriods.map { ($0, $1, $1.timeIntervalSince($0)) }
    }

    private func selectedDayTotalActiveTime(in data: AnalyticsDashboardData) -> Double {
        let sessions = self.selectedDaySessions(in: data)
        return sessions.reduce(0) { $0 + $1.actualFocusSeconds }
    }

    private func topApps(for session: FocusSessionRecord, in data: AnalyticsDashboardData) -> [AnalyticsBreakdownItem] {
        let events = data.appEvents.filter { $0.sessionID == session.id }
        return AnalyticsEngine.shared.buildTopApps(from: events, limit: 3)
    }

    private func topDomains(
        for session: FocusSessionRecord,
        in data: AnalyticsDashboardData) -> [AnalyticsBreakdownItem]
    {
        let visits = data.webVisits.filter { $0.sessionID == session.id }
        return AnalyticsEngine.shared.buildTopDomains(from: visits, limit: 3)
    }

    private var selectedDayRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self.selectedDay)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return (start, end)
    }

    private func previewSessions() -> [FocusSessionRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today) ?? today

        let xcodeStart = calendar.date(byAdding: .hour, value: 9, to: today) ?? today
        let xcodeEnd = calendar.date(byAdding: .minute, value: 30, to: xcodeStart) ?? xcodeStart
        let docsStart = calendar.date(byAdding: .hour, value: 11, to: today) ?? today
        let docsEnd = calendar.date(byAdding: .minute, value: 25, to: docsStart) ?? docsStart
        let reviewStart = calendar.date(byAdding: .hour, value: 10, to: yesterday) ?? yesterday
        let reviewEnd = calendar.date(byAdding: .minute, value: 30, to: reviewStart) ?? reviewStart
        let deepWorkStart = calendar.date(byAdding: .hour, value: 14, to: threeDaysAgo) ?? threeDaysAgo
        let deepWorkEnd = calendar.date(byAdding: .minute, value: 45, to: deepWorkStart) ?? deepWorkStart

        return [
            FocusSessionRecord(
                startedAt: xcodeStart,
                endedAt: xcodeEnd,
                plannedMinutes: 30,
                actualFocusSeconds: 30 * 60,
                sessionMode: .quickSession,
                taskTitle: "Implement analytics dashboard",
                completed: true),
            FocusSessionRecord(
                startedAt: docsStart,
                endedAt: docsEnd,
                plannedMinutes: 25,
                actualFocusSeconds: 25 * 60,
                sessionMode: .quickSession,
                taskTitle: "Read SwiftUI docs",
                completed: true),
            FocusSessionRecord(
                startedAt: reviewStart,
                endedAt: reviewEnd,
                plannedMinutes: 30,
                actualFocusSeconds: 28 * 60,
                sessionMode: .quickSession,
                taskTitle: "Review yesterday notes",
                completed: false,
                interruptedReason: "Stopped early"),
            FocusSessionRecord(
                startedAt: deepWorkStart,
                endedAt: deepWorkEnd,
                plannedMinutes: 45,
                actualFocusSeconds: 42 * 60,
                sessionMode: .quickSession,
                taskTitle: "Deep work block",
                completed: true),
        ]
    }

    private func previewAppEvents(sessions: [FocusSessionRecord]) -> [AppActivityEvent] {
        guard sessions.count >= 4 else { return [] }

        return [
            AppActivityEvent(
                sessionID: sessions[0].id,
                appBundleID: "com.apple.dt.Xcode",
                appName: "Xcode",
                windowTitle: "AnalyticsDashboardView.swift",
                startedAt: sessions[0].startedAt,
                endedAt: sessions[0].endedAt,
                durationSeconds: 24 * 60),
            AppActivityEvent(
                sessionID: sessions[0].id,
                appBundleID: "com.apple.Safari",
                appName: "Safari",
                windowTitle: "Apple Developer Documentation",
                startedAt: sessions[0].startedAt.addingTimeInterval(24 * 60),
                endedAt: sessions[0].endedAt,
                durationSeconds: 6 * 60),
            AppActivityEvent(
                sessionID: sessions[1].id,
                appBundleID: "com.apple.Safari",
                appName: "Safari",
                windowTitle: "SwiftUI Documentation",
                startedAt: sessions[1].startedAt,
                endedAt: sessions[1].endedAt,
                durationSeconds: 25 * 60),
            AppActivityEvent(
                sessionID: sessions[2].id,
                appBundleID: "com.apple.Notes",
                appName: "Notes",
                windowTitle: "Daily Review",
                startedAt: sessions[2].startedAt,
                endedAt: sessions[2].endedAt,
                durationSeconds: 18 * 60),
            AppActivityEvent(
                sessionID: sessions[2].id,
                appBundleID: "com.apple.Safari",
                appName: "Safari",
                windowTitle: "github.com",
                startedAt: sessions[2].startedAt.addingTimeInterval(18 * 60),
                endedAt: sessions[2].endedAt,
                durationSeconds: 10 * 60),
            AppActivityEvent(
                sessionID: sessions[3].id,
                appBundleID: "com.apple.Terminal",
                appName: "Terminal",
                windowTitle: "zsh",
                startedAt: sessions[3].startedAt,
                endedAt: sessions[3].endedAt,
                durationSeconds: 15 * 60),
            AppActivityEvent(
                sessionID: sessions[3].id,
                appBundleID: "com.apple.dt.Xcode",
                appName: "Xcode",
                windowTitle: "FocusSessionManager.swift",
                startedAt: sessions[3].startedAt.addingTimeInterval(15 * 60),
                endedAt: sessions[3].endedAt,
                durationSeconds: 27 * 60),
        ]
    }

    private func previewWebsiteVisits(sessions: [FocusSessionRecord]) -> [WebsiteVisitRecord] {
        guard sessions.count >= 4 else { return [] }

        return [
            WebsiteVisitRecord(
                sessionID: sessions[0].id,
                browserBundleID: "com.apple.Safari",
                browserName: "Safari",
                domain: "developer.apple.com",
                pageTitle: "SwiftUI",
                startedAt: sessions[0].startedAt.addingTimeInterval(24 * 60),
                endedAt: sessions[0].endedAt,
                durationSeconds: 6 * 60),
            WebsiteVisitRecord(
                sessionID: sessions[1].id,
                browserBundleID: "com.apple.Safari",
                browserName: "Safari",
                domain: "developer.apple.com",
                pageTitle: "Observation",
                startedAt: sessions[1].startedAt,
                endedAt: sessions[1].endedAt,
                durationSeconds: 18 * 60),
            WebsiteVisitRecord(
                sessionID: sessions[1].id,
                browserBundleID: "com.apple.Safari",
                browserName: "Safari",
                domain: "github.com",
                pageTitle: "Issue tracker",
                startedAt: sessions[1].startedAt.addingTimeInterval(18 * 60),
                endedAt: sessions[1].endedAt,
                durationSeconds: 7 * 60),
            WebsiteVisitRecord(
                sessionID: sessions[2].id,
                browserBundleID: "com.apple.Safari",
                browserName: "Safari",
                domain: "github.com",
                pageTitle: "Pull requests",
                startedAt: sessions[2].startedAt.addingTimeInterval(18 * 60),
                endedAt: sessions[2].endedAt,
                durationSeconds: 10 * 60),
        ]
    }

    private static let selectedDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }()

    private static func formatDuration(_ seconds: Double) -> String {
        let totalMinutes = Int(seconds / 60)
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return "\(hours)h \(minutes)m"
        }
        return "\(totalMinutes)m"
    }
}

private enum DashboardState {
    case loading
    case empty(DashboardEmptyState)
    case loaded(AnalyticsDashboardData)
}

private enum DashboardEmptyState {
    case noData
    case noSessions
}

private struct OverviewStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: self.icon)
                    .font(.kairos(size: 12, weight: .semibold))
                    .foregroundColor(self.color)

                Text(self.title)
                    .font(.kairosCaption)
                    .foregroundColor(.secondary)
            }

            Text(self.value)
                .font(.kairosTitle2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct AnalyticsDashboardData {
    let sessions: [FocusSessionRecord]
    let appEvents: [AppActivityEvent]
    let webVisits: [WebsiteVisitRecord]
    let heatmapCells: [AnalyticsHeatmapCell]

    var hasVisibleData: Bool {
        !self.sessions.isEmpty
            || !self.appEvents.isEmpty
            || !self.webVisits.isEmpty
            || self.heatmapCells.contains(where: { $0.focusSeconds > 0 })
    }

    var latestFocusDate: Date? {
        let calendar = Calendar.current
        return self.heatmapCells
            .last(where: { $0.focusSeconds > 0 })
            .map { calendar.startOfDay(for: $0.date) }
    }
}

private struct AnalyticsSessionSummaryCard: View {
    let session: FocusSessionRecord
    let appHighlights: [AnalyticsBreakdownItem]
    let websiteHighlights: [AnalyticsBreakdownItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(self.timeRange)
                    .font(.kairos(size: 14, weight: .semibold))

                Spacer(minLength: 12)

                Text(self.statusLabel)
                    .font(.kairos(size: 11, weight: .semibold))
                    .foregroundColor(self.statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(self.statusColor.opacity(0.14))
                    .clipShape(Capsule(style: .continuous))
            }

            if let taskTitle = self.session.taskTitle, !taskTitle.isEmpty {
                Text(taskTitle)
                    .font(.kairos(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }

            Text(self.summaryText)
                .font(.kairosSubheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                self.metaPill(title: "Focus", value: Self.formatDuration(self.session.actualFocusSeconds))
                self.metaPill(title: "Plan", value: "\(self.session.plannedMinutes)m")

                if let interruptedReason = self.session.interruptedReason, !interruptedReason.isEmpty {
                    self.metaPill(title: "Note", value: interruptedReason)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.025)))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    private var timeRange: String {
        let start = Self.timeFormatter.string(from: self.session.startedAt)
        let end = Self.timeFormatter.string(from: self.sessionEnd)
        return "\(start) - \(end)"
    }

    private var sessionEnd: Date {
        if let endedAt = self.session.endedAt {
            return endedAt
        }
        return self.session.startedAt.addingTimeInterval(Double(self.session.plannedMinutes * 60))
    }

    private var statusLabel: String {
        self.session.completed ? "Completed" : "Stopped"
    }

    private var statusColor: Color {
        self.session.completed ? .green : .orange
    }

    private var summaryText: String {
        let highlights = (self.appHighlights + self.websiteHighlights)
            .sorted { $0.seconds > $1.seconds }
            .prefix(3)
            .map { "\($0.name) \(Self.formatDuration($0.seconds))" }

        if highlights.isEmpty {
            return "Focus session recorded. Activity details not available for this session."
        }

        return "Main activity: \(highlights.joined(separator: ", "))."
    }

    private func metaPill(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.kairosCaption2)
                .foregroundColor(.secondary)

            Text(value)
                .font(.kairosCaption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.04))
        .clipShape(Capsule(style: .continuous))
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static func formatDuration(_ seconds: Double) -> String {
        let totalMinutes = Int(seconds / 60)
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return "\(hours)h \(minutes)m"
        }
        return "\(totalMinutes)m"
    }
}

//
//  AnalyticsEngineTests.swift
//  KairosTest
//
//  Unit Testing Bundle
//  Tests for AnalyticsEngine aggregation and computation logic
//

import Foundation
import Testing
@testable import Kairos

struct AnalyticsEngineTests {
    let engine = AnalyticsEngine.shared

    // MARK: - Helpers

    private func makeSession(
        startHour: Int,
        durationSeconds: Double,
        dayOffset: Int
    ) -> FocusSessionRecord {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startedAt = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            .addingTimeInterval(TimeInterval(startHour * 3600))
        let endedAt = startedAt.addingTimeInterval(durationSeconds)
        return FocusSessionRecord(
            startedAt: startedAt,
            endedAt: endedAt,
            plannedMinutes: Int(durationSeconds / 60),
            actualFocusSeconds: durationSeconds,
            sessionMode: .quickSession,
            completed: true)
    }

    private func makeAppEvent(
        sessionID: UUID,
        name: String,
        seconds: Double,
        dayOffset: Int,
        startHour: Int = 9
    ) -> AppActivityEvent {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startedAt = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            .addingTimeInterval(TimeInterval(startHour * 3600))
        return AppActivityEvent(
            sessionID: sessionID,
            appBundleID: "com.test.\(name)",
            appName: name,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(seconds),
            durationSeconds: seconds)
    }

    private func makeWebVisit(
        sessionID: UUID,
        domain: String,
        seconds: Double,
        dayOffset: Int,
        startHour: Int = 9
    ) -> WebsiteVisitRecord {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startedAt = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            .addingTimeInterval(TimeInterval(startHour * 3600))
        return WebsiteVisitRecord(
            sessionID: sessionID,
            browserBundleID: "com.apple.Safari",
            browserName: "Safari",
            domain: domain,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(seconds),
            durationSeconds: seconds)
    }

    // MARK: - buildSummary

    @Test func buildSummaryWithTodaySessions() {
        let sessions = [
            makeSession(startHour: 9, durationSeconds: 3600, dayOffset: 0),
            makeSession(startHour: 14, durationSeconds: 1800, dayOffset: 0),
        ]
        let summary = engine.buildSummary(from: sessions, appEvents: [], webVisits: [])

        #expect(summary.todayFocusSeconds == 5400)
        #expect(summary.streakDays >= 1)
    }

    @Test func buildSummaryWithNoSessions() {
        let summary = engine.buildSummary(from: [], appEvents: [], webVisits: [])
        #expect(summary.todayFocusSeconds == 0)
        #expect(summary.weekFocusSeconds == 0)
        #expect(summary.streakDays == 0)
        #expect(summary.topApps.isEmpty)
        #expect(summary.topDomains.isEmpty)
    }

    @Test func buildSummaryIncludesTopApps() {
        let sessionID = UUID()
        let events = [
            makeAppEvent(sessionID: sessionID, name: "Xcode", seconds: 2400, dayOffset: 0),
            makeAppEvent(sessionID: sessionID, name: "Safari", seconds: 1200, dayOffset: 0),
        ]
        let summary = engine.buildSummary(from: [], appEvents: events, webVisits: [])
        #expect(summary.topApps.count == 2)
        #expect(summary.topApps[0].name == "Xcode")
        #expect(summary.topApps[0].seconds == 2400)
    }

    // MARK: - buildHeatmapCells

    @Test func buildHeatmapCellsReturnsCompleteWeeks() {
        let sessions = [
            makeSession(startHour: 9, durationSeconds: 3600, dayOffset: 0),
            makeSession(startHour: 10, durationSeconds: 1800, dayOffset: -1),
        ]
        let cells = engine.buildHeatmapCells(from: sessions, days: 28)
        #expect(cells.count % 7 == 0)
    }

    @Test func buildHeatmapCellsIntensityLevels() {
        let sessions = [
            makeSession(startHour: 9, durationSeconds: 3600, dayOffset: 0),
        ]
        let cells = engine.buildHeatmapCells(from: sessions, days: 7)
        for cell in cells {
            #expect(cell.intensityLevel >= 0)
            #expect(cell.intensityLevel <= 5)
        }
    }

    @Test func buildHeatmapCellsTodaySessionCount() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessions = [
            makeSession(startHour: 9, durationSeconds: 1800, dayOffset: 0),
            makeSession(startHour: 14, durationSeconds: 1800, dayOffset: 0),
        ]
        let cells = engine.buildHeatmapCells(from: sessions, days: 7)
        let todayCell = cells.first { calendar.isDate($0.date, inSameDayAs: today) }
        #expect(todayCell?.sessionCount == 2)
    }

    @Test func buildHeatmapCellsEmptySessions() {
        let cells = engine.buildHeatmapCells(from: [], days: 7)
        #expect(cells.allSatisfy { $0.focusSeconds == 0 })
        #expect(cells.allSatisfy { $0.intensityLevel == 0 })
    }

    // MARK: - buildTopApps

    @Test func buildTopAppsSortedByDuration() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let sessionID = UUID()
        let events = [
            makeAppEvent(sessionID: sessionID, name: "Safari", seconds: 600, dayOffset: 0),
            makeAppEvent(sessionID: sessionID, name: "Xcode", seconds: 3600, dayOffset: 0),
            makeAppEvent(sessionID: sessionID, name: "Slack", seconds: 1200, dayOffset: 0),
        ]
        let topApps = engine.buildTopApps(from: events, startDate: today, endDate: tomorrow, limit: 5)
        #expect(topApps.count == 3)
        #expect(topApps[0].name == "Xcode")
        #expect(topApps[1].name == "Slack")
        #expect(topApps[2].name == "Safari")
    }

    @Test func buildTopAppsRespectsLimit() {
        let sessionID = UUID()
        let events = (0..<10).map { i in
            makeAppEvent(sessionID: sessionID, name: "App\(i)", seconds: Double(i * 100), dayOffset: 0)
        }
        let topApps = engine.buildTopApps(from: events, limit: 3)
        #expect(topApps.count == 3)
    }

    @Test func buildTopAppsFiltersByDateRange() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let sessionID = UUID()
        let events = [
            makeAppEvent(sessionID: sessionID, name: "Xcode", seconds: 3600, dayOffset: 0),
            makeAppEvent(sessionID: sessionID, name: "OldApp", seconds: 3600, dayOffset: -5),
        ]
        let topApps = engine.buildTopApps(from: events, startDate: today, endDate: tomorrow, limit: 10)
        #expect(topApps.count == 1)
        #expect(topApps[0].name == "Xcode")
    }

    @Test func buildTopAppsEmpty() {
        let topApps = engine.buildTopApps(from: [])
        #expect(topApps.isEmpty)
    }

    // MARK: - buildTopDomains

    @Test func buildTopDomainsSortedByDuration() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let sessionID = UUID()
        let visits = [
            makeWebVisit(sessionID: sessionID, domain: "github.com", seconds: 600, dayOffset: 0),
            makeWebVisit(sessionID: sessionID, domain: "stackoverflow.com", seconds: 3600, dayOffset: 0),
        ]
        let topDomains = engine.buildTopDomains(from: visits, startDate: today, endDate: tomorrow, limit: 5)
        #expect(topDomains.count == 2)
        #expect(topDomains[0].name == "stackoverflow.com")
    }

    @Test func buildTopDomainsRespectsLimit() {
        let sessionID = UUID()
        let visits = (0..<10).map { i in
            makeWebVisit(sessionID: sessionID, domain: "site\(i).com", seconds: Double(i * 100), dayOffset: 0)
        }
        let topDomains = engine.buildTopDomains(from: visits, limit: 3)
        #expect(topDomains.count == 3)
    }

    // MARK: - buildTimeline

    @Test func buildTimelineSortsByStartTime() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessionID = UUID()
        let events = [
            makeAppEvent(sessionID: sessionID, name: "Safari", seconds: 600, dayOffset: 0, startHour: 14),
            makeAppEvent(sessionID: sessionID, name: "Xcode", seconds: 3600, dayOffset: 0, startHour: 9),
        ]
        let timeline = engine.buildTimeline(for: today, appEvents: events, webVisits: [])
        #expect(timeline.count == 2)
        #expect(timeline[0].name == "Xcode")
        #expect(timeline[1].name == "Safari")
    }

    @Test func buildTimelineFiltersCorrectDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessionID = UUID()
        let events = [
            makeAppEvent(sessionID: sessionID, name: "Today", seconds: 600, dayOffset: 0),
            makeAppEvent(sessionID: sessionID, name: "Yesterday", seconds: 600, dayOffset: -1),
        ]
        let timeline = engine.buildTimeline(for: today, appEvents: events, webVisits: [])
        #expect(timeline.count == 1)
        #expect(timeline[0].name == "Today")
    }

    // MARK: - buildDailySnapshots

    @Test func buildDailySnapshotsReturnsCorrectNumberOfDays() {
        let sessions = [
            makeSession(startHour: 9, durationSeconds: 1800, dayOffset: 0),
        ]
        let snapshots = engine.buildDailySnapshots(from: sessions, appEvents: [], webVisits: [], days: 7)
        #expect(snapshots.count == 7)
    }

    @Test func buildDailySnapshotsTodayHasFocusSeconds() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessions = [
            makeSession(startHour: 9, durationSeconds: 3600, dayOffset: 0),
        ]
        let snapshots = engine.buildDailySnapshots(from: sessions, appEvents: [], webVisits: [], days: 7)
        let todaySnapshot = snapshots.first { calendar.isDate($0.date, inSameDayAs: today) }
        #expect(todaySnapshot?.focusSeconds == 3600)
        #expect(todaySnapshot?.sessionCount == 1)
    }
}

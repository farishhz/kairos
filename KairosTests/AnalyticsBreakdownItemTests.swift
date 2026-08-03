//
//  AnalyticsBreakdownItemTests.swift
//  KairosTest
//
//  Unit Testing Bundle
//  Tests for AnalyticsBreakdownItem displayDuration, codable, and related types
//

import Foundation
import Testing
@testable import Kairos

struct AnalyticsBreakdownItemTests {

    // MARK: - displayDuration

    @Test func displayDurationUnderOneHour() {
        let item = AnalyticsBreakdownItem(name: "Test", seconds: 1800)
        #expect(item.displayDuration == "30m")
    }

    @Test func displayDurationExactlyOneHour() {
        let item = AnalyticsBreakdownItem(name: "Test", seconds: 3600)
        #expect(item.displayDuration == "1h 0m")
    }

    @Test func displayDurationMultipleHours() {
        let item = AnalyticsBreakdownItem(name: "Test", seconds: 5400)
        #expect(item.displayDuration == "1h 30m")
    }

    @Test func displayDurationZeroSeconds() {
        let item = AnalyticsBreakdownItem(name: "Test", seconds: 0)
        #expect(item.displayDuration == "0m")
    }

    @Test func displayDurationUnderOneMinute() {
        let item = AnalyticsBreakdownItem(name: "Test", seconds: 30)
        #expect(item.displayDuration == "0m")
    }

    @Test func displayDurationLargeDuration() {
        let item = AnalyticsBreakdownItem(name: "Test", seconds: 36000)
        #expect(item.displayDuration == "10h 0m")
    }

    // MARK: - Init defaults

    @Test func initDefaults() {
        let item = AnalyticsBreakdownItem(name: "Xcode", seconds: 1200)
        #expect(item.name == "Xcode")
        #expect(item.seconds == 1200)
        #expect(item.icon == nil)
        #expect(item.bundleID == nil)
        #expect(item.isWebsite == false)
        #expect(item.percentage == 0)
        #expect(item.iconData == nil)
    }

    @Test func initWithAllParameters() {
        let data = "test".data(using: .utf8)!
        let item = AnalyticsBreakdownItem(
            name: "GitHub",
            seconds: 900,
            icon: "globe",
            bundleID: nil,
            iconData: data,
            isWebsite: true,
            percentage: 25.5)
        #expect(item.name == "GitHub")
        #expect(item.seconds == 900)
        #expect(item.icon == "globe")
        #expect(item.bundleID == nil)
        #expect(item.isWebsite == true)
        #expect(item.percentage == 25.5)
        #expect(item.iconData == data)
    }

    // MARK: - Codable

    @Test func codableRoundTrip() throws {
        let item = AnalyticsBreakdownItem(
            name: "Safari",
            seconds: 2400,
            icon: "globe",
            bundleID: "com.apple.Safari",
            isWebsite: false,
            percentage: 33.3)

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(AnalyticsBreakdownItem.self, from: data)

        #expect(decoded.id == item.id)
        #expect(decoded.name == item.name)
        #expect(decoded.seconds == item.seconds)
        #expect(decoded.icon == item.icon)
        #expect(decoded.bundleID == item.bundleID)
        #expect(decoded.isWebsite == item.isWebsite)
        #expect(decoded.percentage == item.percentage)
    }

    // MARK: - Hashable

    @Test func hashableConformance() {
        let id = UUID()
        var item1 = AnalyticsBreakdownItem(name: "Xcode", seconds: 1200)
        item1.id = id
        var item2 = AnalyticsBreakdownItem(name: "Xcode", seconds: 1200)
        item2.id = id

        var set = Set<AnalyticsBreakdownItem>()
        set.insert(item1)
        set.insert(item2)
        #expect(set.count == 1)
    }

    // MARK: - AnalyticsHeatmapCell

    @Test func heatmapCellDisplayDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cell = AnalyticsHeatmapCell(date: today, focusSeconds: 3600, sessionCount: 2, intensityLevel: 3)
        #expect(!cell.displayDay.isEmpty)
    }

    @Test func heatmapCellWeekdayAbbreviation() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cell = AnalyticsHeatmapCell(date: today, focusSeconds: 0, intensityLevel: 0)
        #expect(!cell.weekdayAbbreviation.isEmpty)
    }

    @Test func heatmapCellHashable() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cell1 = AnalyticsHeatmapCell(date: today, focusSeconds: 100, intensityLevel: 1)
        let cell2 = AnalyticsHeatmapCell(date: today, focusSeconds: 200, intensityLevel: 2)
        var set = Set<AnalyticsHeatmapCell>()
        set.insert(cell1)
        set.insert(cell2)
        #expect(set.count == 2)
    }

    // MARK: - AnalyticsTimelineEntry

    @Test func timelineEntryTimeLabel() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = today.addingTimeInterval(3600)
        let end = today.addingTimeInterval(7200)
        let entry = AnalyticsTimelineEntry(
            startedAt: start,
            endedAt: end,
            kind: .app,
            name: "Xcode",
            seconds: 3600)
        #expect(entry.timeLabel.contains("-"))
    }

    @Test func timelineEntryKinds() {
        #expect(AnalyticsTimelineEntry.TimelineEntryKind.app.rawValue == "app")
        #expect(AnalyticsTimelineEntry.TimelineEntryKind.website.rawValue == "website")
    }
}

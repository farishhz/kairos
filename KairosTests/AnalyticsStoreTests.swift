//
//  AnalyticsStoreTests.swift
//  KairosTest
//
//  Unit Testing Bundle
//  Tests for AnalyticsStore persistence and settings
//

import Foundation
import Testing
@testable import Kairos

struct AnalyticsStoreTests {

    // MARK: - Analytics Enabled Setting

    @Test func analyticsEnabledDefaultsToTrue() {
        let key = AppConstants.AnalyticsSettings.analyticsEnabledKey
        UserDefaults.standard.removeObject(forKey: key)
        #expect(AppConstants.AnalyticsSettings.isAnalyticsEnabled == true)
    }

    @Test func analyticsEnabledCanBeToggled() {
        AppConstants.AnalyticsSettings.isAnalyticsEnabled = false
        #expect(AppConstants.AnalyticsSettings.isAnalyticsEnabled == false)
        AppConstants.AnalyticsSettings.isAnalyticsEnabled = true
        #expect(AppConstants.AnalyticsSettings.isAnalyticsEnabled == true)
    }

    // MARK: - File Constants

    @Test func fileNamesAreNonEmpty() {
        #expect(!AppConstants.AnalyticsSettings.focusSessionsFile.isEmpty)
        #expect(!AppConstants.AnalyticsSettings.appActivityFile.isEmpty)
        #expect(!AppConstants.AnalyticsSettings.websiteVisitsFile.isEmpty)
    }

    @Test func retentionDaysIsReasonable() {
        #expect(AppConstants.AnalyticsSettings.retentionDays >= 30)
    }

    // MARK: - Directory URL

    @Test func analyticsDirectoryURLIsNotCurrentDir() {
        let url = AppConstants.AnalyticsSettings.analyticsDirectoryURL
        #expect(url != URL(fileURLWithPath: "."))
    }

    @Test func analyticsDirectoryURLHasCorrectParent() {
        let url = AppConstants.AnalyticsSettings.analyticsDirectoryURL
        #expect(url.lastPathComponent == "Analytics")
        #expect(url.deletingLastPathComponent().lastPathComponent == "Kairos")
    }

    // MARK: - FocusSessionRecord Model Tests (additional)

    @Test func focusSessionWithInterruptedReason() {
        let session = FocusSessionRecord(
            plannedMinutes: 25,
            actualFocusSeconds: 600,
            sessionMode: .quickSession,
            interruptedReason: "Phone call")
        #expect(session.interruptedReason == "Phone call")
        #expect(session.completed == false)
    }

    @Test func focusSessionTaskPlanMode() {
        let session = FocusSessionRecord(
            plannedMinutes: 50,
            actualFocusSeconds: 3000,
            sessionMode: .taskPlan,
            taskTitle: "Implement auth flow",
            completed: true)
        #expect(session.sessionMode == .taskPlan)
        #expect(session.taskTitle == "Implement auth flow")
        #expect(session.durationMinutes == 50.0)
    }

    // MARK: - AppActivityEvent Model Tests

    @Test func appActivityEventDefaults() {
        let event = AppActivityEvent(
            sessionID: UUID(),
            appBundleID: "com.apple.dt.Xcode",
            appName: "Xcode",
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(1800),
            durationSeconds: 1800)
        #expect(event.windowTitle == nil)
        #expect(event.durationSeconds == 1800)
    }

    @Test func appActivityEventCodableRoundTrip() throws {
        let event = AppActivityEvent(
            sessionID: UUID(),
            appBundleID: "com.google.Chrome",
            appName: "Chrome",
            windowTitle: "GitHub - repo",
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(900),
            durationSeconds: 900)
        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(AppActivityEvent.self, from: data)
        #expect(decoded.appName == "Chrome")
        #expect(decoded.windowTitle == "GitHub - repo")
        #expect(decoded.durationSeconds == 900)
    }

    // MARK: - WebsiteVisitRecord Model Tests

    @Test func websiteVisitRecordDefaults() {
        let visit = WebsiteVisitRecord(
            sessionID: UUID(),
            browserBundleID: "com.apple.Safari",
            browserName: "Safari",
            domain: "github.com",
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(600),
            durationSeconds: 600)
        #expect(visit.pageTitle == nil)
        #expect(visit.browserName == "Safari")
    }

    @Test func websiteVisitRecordCodableRoundTrip() throws {
        let visit = WebsiteVisitRecord(
            sessionID: UUID(),
            browserBundleID: "com.google.Chrome",
            browserName: "Chrome",
            domain: "stackoverflow.com",
            pageTitle: "Swift Testing - Stack Overflow",
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(300),
            durationSeconds: 300)
        let data = try JSONEncoder().encode(visit)
        let decoded = try JSONDecoder().decode(WebsiteVisitRecord.self, from: data)
        #expect(decoded.domain == "stackoverflow.com")
        #expect(decoded.pageTitle == "Swift Testing - Stack Overflow")
        #expect(decoded.browserName == "Chrome")
    }
}

//
//  FocusSessionRecordTests.swift
//  KairosTest
//
//  Unit Testing Bundle
//  Tests for FocusSessionRecord model
//

import Foundation
import Testing
@testable import Kairos

struct FocusSessionRecordTests {

    // MARK: - Duration

    @Test func durationMinutesCalculatesCorrectly() {
        let session = FocusSessionRecord(
            plannedMinutes: 25,
            actualFocusSeconds: 1500,
            sessionMode: .quickSession)
        #expect(session.durationMinutes == 25.0)
    }

    @Test func durationMinutesWithZeroSeconds() {
        let session = FocusSessionRecord(
            plannedMinutes: 25,
            actualFocusSeconds: 0,
            sessionMode: .quickSession)
        #expect(session.durationMinutes == 0)
    }

    @Test func durationMinutesWithPartialMinutes() {
        let session = FocusSessionRecord(
            plannedMinutes: 25,
            actualFocusSeconds: 90,
            sessionMode: .quickSession)
        #expect(session.durationMinutes == 1.5)
    }

    // MARK: - Date Property

    @Test func dateReturnsStartOfDay() {
        let calendar = Calendar.current
        let now = Date()
        let session = FocusSessionRecord(
            startedAt: now,
            plannedMinutes: 25,
            sessionMode: .quickSession)
        #expect(session.date == calendar.startOfDay(for: now))
    }

    // MARK: - Init Defaults

    @Test func initSetsDefaultValues() {
        let session = FocusSessionRecord(plannedMinutes: 10, sessionMode: .quickSession)
        #expect(session.plannedMinutes == 10)
        #expect(session.actualFocusSeconds == 0)
        #expect(session.completed == false)
        #expect(session.taskTitle == nil)
        #expect(session.interruptedReason == nil)
        #expect(session.endedAt == nil)
    }

    @Test func initWithAllParameters() {
        let id = UUID()
        let start = Date()
        let end = start.addingTimeInterval(600)
        let session = FocusSessionRecord(
            id: id,
            startedAt: start,
            endedAt: end,
            plannedMinutes: 10,
            actualFocusSeconds: 600,
            sessionMode: .taskPlan,
            taskTitle: "Test task",
            completed: true,
            interruptedReason: nil)
        #expect(session.id == id)
        #expect(session.startedAt == start)
        #expect(session.endedAt == end)
        #expect(session.sessionMode == .taskPlan)
        #expect(session.taskTitle == "Test task")
        #expect(session.completed == true)
    }

    // MARK: - Codable Round-Trip

    @Test func codableRoundTrip() throws {
        let session = FocusSessionRecord(
            plannedMinutes: 25,
            actualFocusSeconds: 1500,
            sessionMode: .quickSession,
            taskTitle: "Code review",
            completed: true)

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(FocusSessionRecord.self, from: data)

        #expect(decoded.id == session.id)
        #expect(decoded.plannedMinutes == session.plannedMinutes)
        #expect(decoded.actualFocusSeconds == session.actualFocusSeconds)
        #expect(decoded.sessionMode == session.sessionMode)
        #expect(decoded.taskTitle == session.taskTitle)
        #expect(decoded.completed == session.completed)
    }

    // MARK: - Hashable

    @Test func hashableConformance() {
        let id = UUID()
        let s1 = FocusSessionRecord(id: id, plannedMinutes: 25, sessionMode: .quickSession)
        let s2 = FocusSessionRecord(id: id, plannedMinutes: 25, sessionMode: .quickSession)
        var set = Set<FocusSessionRecord>()
        set.insert(s1)
        set.insert(s2)
        #expect(set.count == 1)
    }

    // MARK: - SessionMode

    @Test func sessionModeRawValues() {
        #expect(SessionMode.quickSession.rawValue == "quickSession")
        #expect(SessionMode.taskPlan.rawValue == "taskPlan")
    }

    @Test func sessionModeFromRawValue() {
        #expect(SessionMode(rawValue: "quickSession") == .quickSession)
        #expect(SessionMode(rawValue: "taskPlan") == .taskPlan)
        #expect(SessionMode(rawValue: "invalid") == nil)
    }
}

//
//  SessionStateTests.swift
//  KairosTest
//
//  Unit Testing Bundle
//  Tests for SessionState, SessionMode, SessionPhase, BreakType
//

import Foundation
import Testing
@testable import Kairos

struct SessionStateTests {

    // MARK: - SessionState.mode

    @Test func idleModeReturnsNil() {
        #expect(SessionState.idle.mode == nil)
    }

    @Test func configuredModeReturnsCorrectMode() {
        let state = SessionState.configured(mode: .taskPlan, phase: .focus)
        #expect(state.mode == .taskPlan)
    }

    @Test func runningModeReturnsCorrectMode() {
        let state = SessionState.running(mode: .quickSession, phase: .shortBreak)
        #expect(state.mode == .quickSession)
    }

    @Test func completedModeReturnsCorrectMode() {
        let state = SessionState.completed(mode: .quickSession)
        #expect(state.mode == .quickSession)
    }

    // MARK: - SessionState.phase

    @Test func idlePhaseReturnsNil() {
        #expect(SessionState.idle.phase == nil)
    }

    @Test func configuredPhaseReturnsCorrectPhase() {
        let state = SessionState.configured(mode: .quickSession, phase: .longBreak)
        #expect(state.phase == .longBreak)
    }

    @Test func runningPhaseReturnsCorrectPhase() {
        let state = SessionState.running(mode: .quickSession, phase: .focus)
        #expect(state.phase == .focus)
    }

    @Test func completedPhaseReturnsCompleted() {
        let state = SessionState.completed(mode: .taskPlan)
        #expect(state.phase == .completed)
    }

    // MARK: - SessionState.isIdle

    @Test func isIdleTrueForIdle() {
        #expect(SessionState.idle.isIdle == true)
    }

    @Test func isIdleFalseForOtherStates() {
        #expect(SessionState.configured(mode: .quickSession, phase: .focus).isIdle == false)
        #expect(SessionState.running(mode: .quickSession, phase: .focus).isIdle == false)
        #expect(SessionState.completed(mode: .quickSession).isIdle == false)
    }

    // MARK: - SessionState.isBreakPhase

    @Test func isBreakPhaseTrueForShortBreak() {
        let state = SessionState.running(mode: .quickSession, phase: .shortBreak)
        #expect(state.isBreakPhase == true)
    }

    @Test func isBreakPhaseTrueForLongBreak() {
        let state = SessionState.configured(mode: .quickSession, phase: .longBreak)
        #expect(state.isBreakPhase == true)
    }

    @Test func isBreakPhaseFalseForFocus() {
        let state = SessionState.running(mode: .quickSession, phase: .focus)
        #expect(state.isBreakPhase == false)
    }

    @Test func isBreakPhaseFalseForCompleted() {
        let state = SessionState.completed(mode: .quickSession)
        #expect(state.isBreakPhase == false)
    }

    @Test func isBreakPhaseFalseForIdle() {
        #expect(SessionState.idle.isBreakPhase == false)
    }

    // MARK: - SessionPhase raw values

    @Test func sessionPhaseRawValues() {
        #expect(SessionPhase.focus.rawValue == "focus")
        #expect(SessionPhase.shortBreak.rawValue == "shortBreak")
        #expect(SessionPhase.longBreak.rawValue == "longBreak")
        #expect(SessionPhase.completed.rawValue == "completed")
    }

    @Test func sessionPhaseFromRawValue() {
        #expect(SessionPhase(rawValue: "focus") == .focus)
        #expect(SessionPhase(rawValue: "shortBreak") == .shortBreak)
        #expect(SessionPhase(rawValue: "longBreak") == .longBreak)
        #expect(SessionPhase(rawValue: "completed") == .completed)
        #expect(SessionPhase(rawValue: "invalid") == nil)
    }

    // MARK: - BreakType

    @Test func breakTypeShortSessionPhase() {
        #expect(BreakType.short.sessionPhase == .shortBreak)
    }

    @Test func breakTypeLongSessionPhase() {
        #expect(BreakType.long.sessionPhase == .longBreak)
    }

    @Test func breakTypeRawValues() {
        #expect(BreakType.short.rawValue == "short")
        #expect(BreakType.long.rawValue == "long")
    }

    // MARK: - Equatable

    @Test func sessionStateEquatable() {
        let s1 = SessionState.running(mode: .quickSession, phase: .focus)
        let s2 = SessionState.running(mode: .quickSession, phase: .focus)
        let s3 = SessionState.running(mode: .taskPlan, phase: .focus)
        #expect(s1 == s2)
        #expect(s1 != s3)
    }

    @Test func sessionModeEquatable() {
        #expect(SessionMode.quickSession == SessionMode.quickSession)
        #expect(SessionMode.quickSession != SessionMode.taskPlan)
    }

    @Test func sessionPhaseEquatable() {
        #expect(SessionPhase.focus == SessionPhase.focus)
        #expect(SessionPhase.focus != SessionPhase.shortBreak)
    }
}

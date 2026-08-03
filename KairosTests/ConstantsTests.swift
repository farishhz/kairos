//
//  ConstantsTests.swift
//  KairosTest
//
//  Unit Testing Bundle
//  Tests for AppConstants configuration values
//

import Foundation
import Testing
@testable import Kairos

struct ConstantsTests {

    // MARK: - QuickPresets

    @Test func quickPresetsDefaultsCount() {
        #expect(AppConstants.QuickPresets.defaultValues.count == 3)
    }

    @Test func quickPresetsDefaultsArePositive() {
        for value in AppConstants.QuickPresets.defaultValues {
            #expect(value > 0)
        }
    }

    @Test func quickPresetsMinMaxRange() {
        #expect(AppConstants.QuickPresets.minMinutes < AppConstants.QuickPresets.maxMinutes)
        #expect(AppConstants.QuickPresets.minMinutes >= 1)
        #expect(AppConstants.QuickPresets.maxMinutes <= 120)
    }

    // MARK: - BreakDuration

    @Test func breakDurationsArePositive() {
        #expect(AppConstants.BreakDuration.shortMinutes > 0)
        #expect(AppConstants.BreakDuration.longMinutes > 0)
    }

    @Test func shortBreakIsShorterThanLong() {
        #expect(AppConstants.BreakDuration.shortMinutes < AppConstants.BreakDuration.longMinutes)
    }

    // MARK: - MenuBarSettings

    @Test func menuBarPanelDimensionsArePositive() {
        #expect(AppConstants.MenuBarSettings.panelWidth > 0)
        #expect(AppConstants.MenuBarSettings.panelHeight > 0)
    }

    @Test func menuBarDefaultPresetMinutesIsReasonable() {
        #expect(AppConstants.MenuBarSettings.defaultPresetMinutes >= 5)
        #expect(AppConstants.MenuBarSettings.defaultPresetMinutes <= 60)
    }

    // MARK: - SoundSettings

    @Test func soundSettingsVolumeRange() {
        #expect(AppConstants.SoundSettings.minVolume == 0.0)
        #expect(AppConstants.SoundSettings.maxVolume == 1.0)
        #expect(AppConstants.SoundSettings.defaultVolume > AppConstants.SoundSettings.minVolume)
        #expect(AppConstants.SoundSettings.defaultVolume <= AppConstants.SoundSettings.maxVolume)
    }

    @Test func soundOptionsAreNonEmpty() {
        #expect(AppConstants.SoundSettings.options.count > 0)
    }

    @Test func soundOptionsHaveUniqueIds() {
        let ids = AppConstants.SoundSettings.options.map(\.id)
        #expect(ids.count == Set(ids).count)
    }

    // MARK: - FloatingThemeSettings

    @Test func floatingOpacityRange() {
        #expect(AppConstants.FloatingThemeSettings.minOpacity < AppConstants.FloatingThemeSettings.maxOpacity)
        #expect(AppConstants.FloatingThemeSettings.defaultOpacity >= AppConstants.FloatingThemeSettings.minOpacity)
        #expect(AppConstants.FloatingThemeSettings.defaultOpacity <= AppConstants.FloatingThemeSettings.maxOpacity)
    }

    // MARK: - FloatingLayoutSettings

    @Test func floatingLayoutDimensionsArePositive() {
        #expect(AppConstants.FloatingLayoutSettings.timerOnlyWidth > 0)
        #expect(AppConstants.FloatingLayoutSettings.timerOnlyHeight > 0)
        #expect(AppConstants.FloatingLayoutSettings.timerOnlyFontSize > 0)
    }

    // MARK: - AnalyticsSettings

    @Test func analyticsDirectoryURLContainsKairos() {
        let url = AppConstants.AnalyticsSettings.analyticsDirectoryURL
        #expect(url.lastPathComponent == "Analytics")
        #expect(url.path.contains("Kairos"))
    }

    @Test func weeklySummaryDaysIs7() {
        #expect(AppConstants.AnalyticsSettings.weeklySummaryDays == 7)
    }

    @Test func defaultDashboardRangeDaysIsReasonable() {
        #expect(AppConstants.AnalyticsSettings.defaultDashboardRangeDays >= 7)
        #expect(AppConstants.AnalyticsSettings.defaultDashboardRangeDays <= 90)
    }

    @Test func heatmapDaysIsReasonable() {
        #expect(AppConstants.AnalyticsSettings.heatmapDays >= 7)
    }
}

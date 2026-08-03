import SwiftUI

struct GeneralSettingsPane: View {
    @AppStorage(AppConstants.QuickPresets.preset1Key)
    private var quickPreset1: Int = AppConstants.QuickPresets.defaultValues[0]
    @AppStorage(AppConstants.QuickPresets.preset2Key)
    private var quickPreset2: Int = AppConstants.QuickPresets.defaultValues[1]
    @AppStorage(AppConstants.QuickPresets.preset3Key)
    private var quickPreset3: Int = AppConstants.QuickPresets.defaultValues[2]
    @AppStorage(AppConstants.SoundSettings.selectedSoundKey)
    private var selectedSoundID: String = AppConstants.SoundSettings.defaultSoundID
    @AppStorage(AppConstants.SoundSettings.autoMuteAfter5SecondsKey)
    private var autoMuteAfter5Seconds: Bool = true
    @AppStorage(AppConstants.SoundSettings.volumeKey)
    private var soundVolume: Double = AppConstants.SoundSettings.defaultVolume
    @AppStorage(AppConstants.MenuBarSettings.compactIconKey)
    private var compactMenuBarIcon: Bool = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsPageHeader(
                    title: "General",
                    subtitle: "Manage daily presets, sound behavior, and menu bar basics.")

                quickPresetsSection
                completionSoundSection
                menuBarSection
            }
            .padding(24)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .onAppear {
            if !AppConstants.SoundSettings.options.contains(where: { $0.id == selectedSoundID }) {
                selectedSoundID = AppConstants.SoundSettings.defaultSoundID
            }
            soundVolume = clampVolume(soundVolume)
        }
        .onChange(of: quickPreset1) { newValue in
            quickPreset1 = clampPreset(newValue)
        }
        .onChange(of: quickPreset2) { newValue in
            quickPreset2 = clampPreset(newValue)
        }
        .onChange(of: quickPreset3) { newValue in
            quickPreset3 = clampPreset(newValue)
        }
        .onChange(of: soundVolume) { newValue in
            soundVolume = clampVolume(newValue)
        }
    }

    private var quickPresetsSection: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Quick presets",
                    subtitle: "Three fast durations for menu bar launch.")

                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        presetField(value: $quickPreset1)
                        presetField(value: $quickPreset2)
                        presetField(value: $quickPreset3)
                    }
                    Spacer()
                }
            }
        }
    }

    private var completionSoundSection: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Completion sound",
                    subtitle: "Choose how session ending feels and how loud it lands.")

                SettingsRow(title: "Sound", subtitle: "Played when focus or break finishes.") {
                    Picker("", selection: $selectedSoundID) {
                        ForEach(AppConstants.SoundSettings.options) { option in
                            Text(option.title).tag(option.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 220, alignment: .trailing)
                }

                Divider()

                SettingsRow(title: "Volume", subtitle: "Applies to all completion sounds.") {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.1")
                            .foregroundColor(.secondary)
                        CustomSlider(
                            value: $soundVolume,
                            range: AppConstants.SoundSettings.minVolume...AppConstants.SoundSettings.maxVolume,
                            step: 0.05)
                            .frame(width: 180)
                        Image(systemName: "speaker.wave.3")
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                SettingsRow(
                    title: "Auto mute after 5 seconds",
                    subtitle: "Keep alert short after timer completes.")
                {
                    Toggle("", isOn: $autoMuteAfter5Seconds)
                        .toggleStyle(.switch)
                }
            }
        }
    }

    private var menuBarSection: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Menu bar",
                    subtitle: "Control how Kairos looks in compact top-bar mode.")

                SettingsRow(
                    title: "Compact icon",
                    subtitle: "Use smaller menu bar presence for cleaner desktop.")
                {
                    Toggle("", isOn: $compactMenuBarIcon)
                        .toggleStyle(.switch)
                }
            }
        }
    }

    private func presetField(value: Binding<Int>) -> some View {
        TextField("", value: value, formatter: Self.presetFormatter)
            .textFieldStyle(.roundedBorder)
            .frame(width: 64)
            .multilineTextAlignment(.center)
    }

    private func clampPreset(_ value: Int) -> Int {
        min(AppConstants.QuickPresets.maxMinutes, max(AppConstants.QuickPresets.minMinutes, value))
    }

    private func clampVolume(_ value: Double) -> Double {
        min(AppConstants.SoundSettings.maxVolume, max(AppConstants.SoundSettings.minVolume, value))
    }

    private static let presetFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
}

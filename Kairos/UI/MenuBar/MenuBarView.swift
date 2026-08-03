import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var session = FocusSessionManager.shared
    @State private var minutes: Int = 25

    @AppStorage(AppConstants.QuickPresets.preset1Key)
    private var quickPreset1: Int = AppConstants.QuickPresets.defaultValues[0]
    @AppStorage(AppConstants.QuickPresets.preset2Key)
    private var quickPreset2: Int = AppConstants.QuickPresets.defaultValues[1]
    @AppStorage(AppConstants.QuickPresets.preset3Key)
    private var quickPreset3: Int = AppConstants.QuickPresets.defaultValues[2]
    @AppStorage(AppConstants.MenuBarSettings.selectedPresetMinutesKey)
    private var selectedPresetMinutes: Int = AppConstants.MenuBarSettings.defaultPresetMinutes

    private let minTime = AppConstants.QuickPresets.minMinutes
    private let maxTime = AppConstants.QuickPresets.maxMinutes

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RulerPicker(value: self.$minutes, range: self.minTime...self.maxTime)
                .frame(height: 30)
                .padding(.top, 12)
                .padding(.bottom, 4)
                .padding(.horizontal, 10)
                .accessibilityLabel("Focus Duration")
                .accessibilityValue("\(self.minutes) minutes")

            HStack(spacing: 8) {
                if self.session.isActive {
                    Button("cancel") {
                        self.cancelSession()
                    }
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .buttonStyle(.plain)

                    Button("restart") {
                        self.startSession()
                    }
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .buttonStyle(.plain)
                } else {
                    ForEach(
                        Array([self.quickPreset1, self.quickPreset2, self.quickPreset3].enumerated()),
                        id: \.offset)
                    { _, preset in
                        Button(action: {
                            self.minutes = preset
                            self.selectedPresetMinutes = preset
                        }, label: {
                            Text("\(preset)m")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(self.minutes == preset ? .primary : .secondary)
                                .frame(minWidth: 30)
                        })
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            HStack {
                Button(action: self.handlePrimaryAction) {
                    Text(self.primaryButtonTitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)

                Spacer(minLength: 0)

                    Menu(content: {
                        Button("Settings...") {
                            SettingsWindowController.show()
                        }
                        .keyboardShortcut(",", modifiers: .command)
                        Button("Check for Updates...") {
                            UpdaterManager.shared.checkForUpdates()
                        }
                        .disabled(!UpdaterManager.shared.canCheckForUpdates)
                        Button("Contact Us") { self.openContact() }
                        Divider()
                        Button("Quit") { NSApp.terminate(nil) }
                            .keyboardShortcut("q", modifiers: .command)
                    }, label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                })
                .menuStyle(.borderlessButton)
                .fixedSize()
                .hideMenuIndicator()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(
            width: AppConstants.MenuBarSettings.panelWidth,
            height: AppConstants.MenuBarSettings.panelHeight)
        .background(VisualEffectBackground())
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
        .onAppear {
            self.minutes = self.clampMinutes(self.selectedPresetMinutes)
        }
        .onChange(of: self.minutes) { newValue in
            let clamped = self.clampMinutes(newValue)
            if self.minutes != clamped {
                self.minutes = clamped
                return
            }
            self.selectedPresetMinutes = clamped
        }
        .onChange(of: self.selectedPresetMinutes) { newValue in
            let clamped = self.clampMinutes(newValue)
            if self.minutes != clamped {
                self.minutes = clamped
            }
        }
    }

    // MARK: - Actions

    private func startSession() {
        let clampedMinutes = self.clampMinutes(self.minutes)
        self.minutes = clampedMinutes
        self.selectedPresetMinutes = clampedMinutes
        self.session.start(task: "Focus Session", duration: TimeInterval(clampedMinutes * 60))
        WindowManager.shared.showFloating()
    }

    private func openContact() {
        if let url = URL(string: "mailto:support@kairos.app") {
            NSWorkspace.shared.open(url)
        }
    }

    private var primaryButtonTitle: String {
        if !self.session.isActive { return "start" }
        return self.session.isPaused ? "resume" : "pause"
    }

    private func handlePrimaryAction() {
        if !self.session.isActive {
            self.startSession()
            return
        }

        if self.session.isPaused {
            self.session.resume()
        } else {
            self.session.pause()
        }
    }

    private func cancelSession() {
        self.session.stop()
        WindowManager.shared.hideFloating()
    }

    private func clampMinutes(_ value: Int) -> Int {
        min(self.maxTime, max(self.minTime, value))
    }
}

struct RulerPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        GeometryReader { geo in
            let totalRange = CGFloat(self.range.upperBound - self.range.lowerBound)
            let stepWidth = geo.size.width / totalRange

            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(0...Int(totalRange), id: \.self) { index in
                        Rectangle()
                            .fill(Color.gray.opacity(index % 5 == 0 ? 0.5 : 0.2))
                            .frame(width: 1, height: index % 5 == 0 ? 20 : 10)
                            .frame(maxWidth: .infinity)
                    }
                }

                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 28)
                    .shadow(color: .white.opacity(0.5), radius: 2)
                    .offset(x: CGFloat(self.value - self.range.lowerBound) * stepWidth)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let locationX = drag.location.x
                        let percent = max(0, min(1, locationX / geo.size.width))
                        let newValue = Int(Double(self.range.lowerBound) + (percent * Double(totalRange)))
                        self.value = newValue
                    })
        }
    }
}

extension View {
    @ViewBuilder
    func hideMenuIndicator() -> some View {
        if #available(macOS 12.0, *) {
            self.menuIndicator(.hidden)
        } else {
            self
        }
    }
}

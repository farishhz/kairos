import SwiftUI

struct FloatingTimerView: View {
    private static let timerFontName = "RobotoMono-VariableFont_wght"

    @ObservedObject private var timer = FocusSessionManager.shared.timerService

    @AppStorage(AppConstants.FloatingThemeSettings.opacityKey)
    private var floatingOpacity: Double = AppConstants.FloatingThemeSettings.defaultOpacity
    @AppStorage(AppConstants.FloatingThemeSettings.selectedThemeKey)
    private var selectedThemeID: String = AppConstants.FloatingThemeSettings.defaultThemeID

    var body: some View {
        let theme = self.selectedTheme
        let clampedOpacity = min(
            AppConstants.FloatingThemeSettings.maxOpacity,
            max(AppConstants.FloatingThemeSettings.minOpacity, self.floatingOpacity))

        self.timerOnlyContent(theme: theme)
            .frame(
                width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
                height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)
            .background(self.panelBackground(theme: theme, opacity: clampedOpacity))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .animation(.easeInOut(duration: 0.2), value: self.floatingOpacity)
    }

    private var selectedTheme: FloatingTheme {
        FloatingTheme.from(id: self.selectedThemeID)
    }

    private func timerOnlyContent(theme: FloatingTheme) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Text(self.format(self.timer.remainingTime))
                .font(.custom(Self.timerFontName, size: AppConstants.FloatingLayoutSettings.timerOnlyFontSize))
                .foregroundColor(theme.textColor)
                .baselineOffset(-(AppConstants.FloatingLayoutSettings.timerOnlyFontSize * 0.15))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func panelBackground(theme: FloatingTheme, opacity: Double) -> some View {
        let panelShape = RoundedRectangle(cornerRadius: 18)

        return panelShape.fill(theme.backgroundColor.opacity(opacity))
            .shadow(color: Color.black.opacity(0.30), radius: 32, x: 0, y: 32)
            .shadow(color: Color.black.opacity(0.30), radius: 16, x: 0, y: 16)
            .shadow(color: Color.black.opacity(0.24), radius: 8, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.24), radius: 4, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: -8)
            .shadow(color: Color.black.opacity(0.24), radius: 2, x: 0, y: 2)
            .overlay(
                panelShape
                    .stroke(Color.black.opacity(1.0), lineWidth: 1)
            )
            .overlay(
                panelShape
                    .fill(Color.white.opacity(0.08))
                    .blendMode(.plusLighter)
            )
            .overlay(
                panelShape
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0.20), location: 0.0),
                                .init(color: Color.white.opacity(0.0), location: 0.15)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }

    private func format(_ time: TimeInterval) -> String {
        let total = max(0, Int(time.rounded(.down)))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

import SwiftUI

struct AnalyticsEmptyStateView: View {
    var icon: String = "chart.bar.xaxis"
    var message: String = "No data yet"
    var subtitle: String = "Start a focus session to begin tracking your activity."
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        SettingsSurfaceCard {
            VStack(spacing: 16) {
                Image(systemName: self.icon)
                    .font(.kairos(size: 48))
                    .foregroundColor(.secondary)

                Text(self.message)
                    .font(.kairosHeadline)
                    .foregroundColor(.primary)

                Text(self.subtitle)
                    .font(.kairosSubheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

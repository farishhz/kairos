import SwiftUI

/// Displays active time visualization with segmented picker for timeline or pie chart view.
/// Wraps HourlyTimelineChart and UsagePieChart behind a toggle control.
struct AnalyticsActiveTimeCard: View {
    /// Date being visualized
    let selectedDate: Date
    /// Merged work periods for the selected day
    let workPeriods: [(startTime: Date, endTime: Date, duration: TimeInterval)]
    /// Total active time in seconds
    let totalActiveTime: TimeInterval
    /// Top apps by usage duration
    let topApps: [AnalyticsBreakdownItem]
    /// Top websites by usage duration
    let topWebsites: [AnalyticsBreakdownItem]

    @State private var currentPage = 0

    var body: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Active Time")
                        .font(.kairos(size: 16, weight: .semibold))
                    Spacer()
                    Text(formatDuration(self.totalActiveTime))
                        .font(.kairos(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Picker(selection: $currentPage, label: EmptyView()) {
                    Image(systemName: "chart.line.uptrend.xyaxis").tag(0)
                    Image(systemName: "chart.pie").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
                .fixedSize()

                Group {
                    if currentPage == 0 {
                        AnalyticsHourlyTimelineChart(
                            selectedDate: self.selectedDate,
                            workPeriods: self.workPeriods)
                    } else {
                        AnalyticsUsagePieChart(
                            selectedDate: self.selectedDate,
                            topApps: self.topApps)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    /// Formats seconds into human-readable duration string
    /// - Parameter seconds: Duration in seconds
    /// - Returns: Formatted string like "2h 30m" or "45m"
    private func formatDuration(_ seconds: Double) -> String {
        let totalMinutes = Int(seconds / 60)
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return "\(hours)h \(minutes)m"
        }
        return "\(totalMinutes)m"
    }
}

import SwiftUI

/// Displays a 24-hour horizontal timeline with blue bars representing work periods.
/// Shows hour labels at 3-hour intervals (0, 3, 6, 9, 12, 15, 18, 21).
struct AnalyticsHourlyTimelineChart: View {
    /// Date being visualized
    let selectedDate: Date
    /// Merged work periods for the selected day
    let workPeriods: [(startTime: Date, endTime: Date, duration: TimeInterval)]

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                let timelineWidth = geometry.size.width
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: self.selectedDate)
                let dayDuration: TimeInterval = 24 * 3600

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 60)
                        .cornerRadius(4)

                    ForEach(Array(self.workPeriods.enumerated()), id: \.offset) { _, period in
                        let sessionStart = period.startTime.timeIntervalSince(startOfDay)
                        let sessionDuration = period.duration
                        let startPosition = (sessionStart / dayDuration) * timelineWidth
                        let sessionWidth = max((sessionDuration / dayDuration) * timelineWidth, 2)

                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: sessionWidth, height: 60)
                            .cornerRadius(2)
                            .offset(x: startPosition)
                    }
                }
            }
            .frame(height: 60)

            HStack {
                ForEach(Array(stride(from: 0, through: 21, by: 3)), id: \.self) { hour in
                    Text("\(hour)")
                        .font(.kairosCaption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(height: 80)
    }
}

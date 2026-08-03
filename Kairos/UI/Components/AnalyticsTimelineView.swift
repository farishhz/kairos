import SwiftUI

struct AnalyticsTimelineView: View {
    let date: Date
    let entries: [AnalyticsTimelineEntry]

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }()

    var body: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Activity Timeline",
                    subtitle: self.subtitleText)

                if self.entries.isEmpty {
                    Text("No activity recorded for this day.")
                        .font(.kairosSubheadline)
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(self.entries) { entry in
                                TimelineRow(entry: entry)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
        }
    }

    private var subtitleText: String {
        "Chronological view of tracked apps and sites for \(Self.dayFormatter.string(from: self.date))."
    }
}

struct TimelineRow: View {
    let entry: AnalyticsTimelineEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(entry.timeLabel)
                    .font(.kairosCaption)
                    .foregroundColor(.secondary)
                Text(formatDuration(entry.seconds))
                    .font(.kairosCaption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: entry.kind == .app ? "macwindow" : "network")
                        .foregroundColor(entry.kind == .app ? .blue : .purple)
                    Text(entry.name)
                        .font(.kairosSubheadline)
                }

                if let detail = entry.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.kairosCaption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }

    private func formatDuration(_ seconds: Double) -> String {
        if seconds < 60 {
            return "<1m"
        }
        let mins = Int(seconds / 60)
        if mins >= 60 {
            return "\(mins / 60)h \(mins % 60)m"
        }
        return "\(mins)m"
    }
}

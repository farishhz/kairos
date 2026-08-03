import SwiftUI

struct AnalyticsHeatmapView: View {
    let cells: [AnalyticsHeatmapCell]
    @Binding var selectedDate: Date

    private let intensityColors: [Color] = [
        Color(red: 0.20, green: 0.21, blue: 0.22),
        Color(red: 0.28, green: 0.31, blue: 0.32),
        Color(red: 0.34, green: 0.42, blue: 0.39),
        Color(red: 0.44, green: 0.55, blue: 0.48),
        Color(red: 0.58, green: 0.71, blue: 0.58),
        Color(red: 0.74, green: 0.84, blue: 0.68),
    ]
    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 4 

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

   var body: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                self.header

                if self.weekColumns.isEmpty {
                    Text("No focus history yet.")
                        .font(.kairosSubheadline)
                        .foregroundColor(.secondary)
                } else {
                    // Pakai GeometryReader hanya untuk month axis positioning
                    VStack(alignment: .leading, spacing: 6) {
                        // Grid heatmap — HStack spacing = cellSpacing (bukan columnWidth)
                        HStack(alignment: .top, spacing: self.cellSpacing) {
                            ForEach(Array(self.weekColumns.enumerated()), id: \.offset) { _, week in
                                VStack(spacing: self.cellSpacing) {
                                    ForEach(week, id: \.id) { cell in
                                        self.heatmapCell(cell)
                                    }
                                }
                                .frame(width: self.cellSize)
                            }
                        }

                        // Month axis — pakai HStack spacing yang SAMA
                        HStack(alignment: .center, spacing: self.cellSpacing) {
                            ForEach(Array(self.weekColumns.enumerated()), id: \.offset) { index, week in
                                // Lebar label = cellSize kolom itu + sisa sampai label berikutnya
                                // Tapi cukup beri minWidth = 0, maxWidth = .infinity agar tidak terpotong
                                // dan sembunyikan jika nil
                                if let label = self.monthLabel(for: week, index: index) {
                                    Text(label)
                                        .font(.kairos(size: 10, weight: .medium))
                                        .foregroundColor(.primary.opacity(0.78))
                                        .fixedSize()  // <-- KUNCI: tidak terpotong
                                        .frame(width: self.cellSize, alignment: .leading)
                                } else {
                                    Color.clear
                                        .frame(width: self.cellSize)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Activity")
                .font(.kairos(size: 17, weight: .medium))
                .foregroundColor(.primary)

            Spacer(minLength: 16)

            if let selectedCell = self.selectedCell {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Self.dayFormatter.string(from: selectedCell.date))
                        .font(.kairos(size: 12, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.82))

                    Text(self.focusSummary(for: selectedCell))
                        .font(.kairosCaption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var weekColumns: [[AnalyticsHeatmapCell]] {
        self.cells.chunked(into: 7)
    }

    private var gridHeight: CGFloat {
        let rows: CGFloat = 7
        let monthAxisHeight: CGFloat = 14
        let spacing: CGFloat = 6  // spacing antara grid dan month axis
        return (rows * self.cellSize) + (CGFloat(rows - 1) * self.cellSpacing) + spacing + monthAxisHeight
    }

    private var selectedCell: AnalyticsHeatmapCell? {
        self.cells.first { Calendar.current.isDate($0.date, inSameDayAs: self.selectedDate) }
    }

    private func monthAxis(metrics: GridMetrics) -> some View {
        HStack(alignment: .center, spacing: self.cellSpacing) {
            ForEach(Array(self.weekColumns.enumerated()), id: \.offset) { index, week in
                Text(self.monthLabel(for: week, index: index) ?? "")
                    .font(.kairos(size: 10, weight: .medium))
                    .foregroundColor(.primary.opacity(0.78))
                    .lineLimit(1)
                    .frame(width: metrics.columnWidth, alignment: .leading)
            }
        }
    }

    private func heatmapCell(_ cell: AnalyticsHeatmapCell) -> some View {
        let isSelected = Calendar.current.isDate(cell.date, inSameDayAs: self.selectedDate)
        let cornerRadius = min(3, max(2, self.cellSize * 0.2))

        return Button {
            self.selectedDate = cell.date
        } label: {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(self.intensityColors[cell.intensityLevel])
                .frame(width: self.cellSize, height: self.cellSize)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            isSelected
                                ? Color(red: 0.56, green: 0.71, blue: 0.58)
                                : Color.black.opacity(0.18),
                            lineWidth: isSelected ? 1.8 : 0.8))
                .shadow(
                    color: isSelected ? Color(red: 0.56, green: 0.71, blue: 0.58).opacity(0.22) : .clear,
                    radius: 6,
                    y: 1)
        }
        .buttonStyle(.plain)
        .help(self.helpText(for: cell))
    }

    private func monthLabel(for week: [AnalyticsHeatmapCell], index: Int) -> String? {
        guard let firstDay = week.first?.date else { return nil }

        if index == 0 {
            return Self.monthFormatter.string(from: firstDay)
        }

        guard let previousWeek = self.weekColumns[safe: index - 1],
              let previousDay = previousWeek.first?.date else {
            return Self.monthFormatter.string(from: firstDay)
        }

        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: firstDay)
        let previousMonth = calendar.component(.month, from: previousDay)
        if currentMonth != previousMonth {
            return Self.monthFormatter.string(from: firstDay)
        }

        return nil
    }

    private func formatDate(_ date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    private func focusSummary(for cell: AnalyticsHeatmapCell) -> String {
        let minutes = Int(cell.focusSeconds / 60)
        guard cell.sessionCount > 0 else {
            return "\(minutes) min focus"
        }

        return "\(minutes) min focus • \(self.sessionCountLabel(cell.sessionCount))"
    }

    private func helpText(for cell: AnalyticsHeatmapCell) -> String {
        "\(self.formatDate(cell.date)): \(self.focusSummary(for: cell))"
    }

    private func sessionCountLabel(_ count: Int) -> String {
        count == 1 ? "1 session" : "\(count) sessions"
    }

    private func gridMetrics(for width: CGFloat) -> GridMetrics {
        let safeWidth = max(width, 320)
        let columnCount = max(CGFloat(self.weekColumns.count), 1)
        let totalSpacing = CGFloat(max(self.weekColumns.count - 1, 0)) * self.cellSpacing
        let columnWidth = (safeWidth - totalSpacing) / columnCount
        let cellSize = min(14, max(11, columnWidth * 0.55))

        return GridMetrics(
            cellSize: cellSize,
            columnWidth: max(columnWidth, cellSize),
            cornerRadius: min(3, max(2, cellSize * 0.2)))
    }
}

private struct GridMetrics {
    let cellSize: CGFloat
    let columnWidth: CGFloat
    let cornerRadius: CGFloat
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }

    subscript(safe index: Int) -> Element? {
        guard self.indices.contains(index) else { return nil }
        return self[index]
    }
}

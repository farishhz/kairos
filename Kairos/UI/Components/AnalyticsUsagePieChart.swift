import SwiftUI

/// Displays a donut chart showing top 5 apps by usage duration with color-coded legend.
/// Uses overlay-based rendering for macOS 11+ compatibility.
struct AnalyticsUsagePieChart: View {
    /// Date being visualized
    let selectedDate: Date
    /// Top apps by usage duration
    let topApps: [AnalyticsBreakdownItem]

    private var topFive: [AnalyticsBreakdownItem] {
        Array(self.topApps.prefix(5))
    }

    private let colors: [Color] = [.blue, .green, .orange, .red, .purple]

    var body: some View {
        HStack(spacing: 12) {
            PieChartRing(items: self.topFive, colors: self.colors)
                .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                ForEach(Array(self.topFive.enumerated()), id: \.element.id) { index, app in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(self.colors[index % self.colors.count].opacity(0.8))
                            .frame(width: 8, height: 8)
                        Text(app.name)
                            .font(.kairosCaption2)
                            .lineLimit(1)
                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .frame(height: 80)
    }
}

private struct PieChartRing: View {
    let items: [AnalyticsBreakdownItem]
    let colors: [Color]

    var body: some View {
        ZStack {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, _ in
                PieSlice(
                    startAngle: self.startAngle(for: index),
                    endAngle: self.endAngle(for: index))
                .fill(self.colors[index % self.colors.count].opacity(0.8))
            }
            Circle()
                .fill(Color(NSColor.windowBackgroundColor))
                .frame(width: 40, height: 40)
        }
    }

    private func startAngle(for index: Int) -> Angle {
        let total = items.reduce(0) { $0 + $1.seconds }
        guard total > 0 else { return .zero }
        var angle: Double = -90
        for i in 0..<index {
            angle += (items[i].seconds / total) * 360
        }
        return .degrees(angle)
    }

    private func endAngle(for index: Int) -> Angle {
        let total = items.reduce(0) { $0 + $1.seconds }
        guard total > 0 else { return .zero }
        var angle: Double = -90
        for i in 0...index {
            angle += (items[i].seconds / total) * 360
        }
        return .degrees(angle)
    }
}

private struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

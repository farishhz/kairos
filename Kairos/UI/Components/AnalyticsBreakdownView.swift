import SwiftUI
import Combine

struct AnalyticsBreakdownView: View {
    let date: Date
    let apps: [AnalyticsBreakdownItem]
    let domains: [AnalyticsBreakdownItem]
    @ObservedObject private var permissionsManager = AnalyticsPermissionsManager.shared

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }()

    var body: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionHeading(
                    title: "Daily Breakdown",
                    subtitle: "Top apps and websites for \(Self.dayFormatter.string(from: self.date)).")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    BreakdownColumn(
                        title: "Top Apps",
                        icon: "macwindow",
                        items: self.apps,
                        emptyMessage: "No app activity on this day.")

                    if self.permissionsManager.automationPermissionStatus != .granted && self.domains.isEmpty {
                        WebsitePermissionColumn(
                            openSettings: { self.permissionsManager.openSystemPreferences() })
                    } else {
                        BreakdownColumn(
                            title: "Top Websites",
                            icon: "network",
                            items: self.domains,
                            emptyMessage: "No website activity recorded.")
                    }
                }
            }
        }
    }
}

private struct BreakdownColumn: View {
    let title: String
    let icon: String
    let items: [AnalyticsBreakdownItem]
    let emptyMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(self.title, systemImage: self.icon)
                .font(.kairos(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            if self.items.isEmpty {
                EmptyStateContent(message: self.emptyMessage)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(self.items) { item in
                            BreakdownRow(item: item)
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(16)
        .background(ColumnBackground())
    }
}

private struct EmptyStateContent: View {
    let message: String
    
    var body: some View {
        Text(self.message)
            .font(.kairosSubheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
    }
}

private struct ColumnBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.025))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

private struct WebsitePermissionColumn: View {
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Top Websites", systemImage: "network")
                .font(.kairos(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            Spacer(minLength: 0)

            PermissionAlert(openSettings: openSettings)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .padding(16)
        .background(ColumnBackground())
    }
}

private struct PermissionAlert: View {
    let openSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "lock.shield")
                .font(.kairos(size: 28))
                .foregroundColor(.orange)

            Text("Website tracking requires permission")
                .font(.kairosHeadline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Kairos needs Automation permission to read browser tabs.")
                    .font(.kairosSubheadline)
                    .foregroundColor(.secondary)

                Text("Enable Kairos in System Settings > Privacy & Security > Automation for each browser.")
                    .font(.kairosSubheadline)
                    .foregroundColor(.secondary)

                Text("Top apps will still be tracked without this permission.")
                    .font(.kairosSubheadline)
                    .foregroundColor(.secondary)
            }

            Button(
                action: openSettings,
                label: {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape")
                        Text("Open Automation Settings")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                })
            .buttonStyle(.plain)
        }
    }
}

private struct BreakdownRow: View {
    let item: AnalyticsBreakdownItem
    @State private var fetchedIconData: Data?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 10) {
                if item.isWebsite {
                    AnalyticsIconView(
                        type: .website(domain: item.name, iconData: effectiveIconData),
                        size: 22)
                } else if let bundleID = item.bundleID {
                    AnalyticsIconView(
                        type: .app(bundleID: bundleID, iconData: effectiveIconData),
                        size: 22)
                } else {
                    AnalyticsIconView(
                        type: .app(bundleID: item.name, iconData: effectiveIconData),
                        size: 22)
                }

                Text(self.item.name)
                    .font(.kairos(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(self.item.displayDuration)
                    .font(.kairos(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            ProgressBar(percentage: self.item.percentage)

            PercentageLabel(percentage: self.item.percentage)
        }
        .onAppear {
            Task {
                await loadIconIfNeeded()
            }
        }
    }

    private var effectiveIconData: Data? {
        item.iconData ?? fetchedIconData
    }

    @MainActor
    private func loadIconIfNeeded() async {
        guard item.iconData == nil else { return }

        if item.isWebsite {
            let data = await WebIconService.shared.favicon(for: item.name, sourceURL: nil)
            if let data {
                self.fetchedIconData = data
            }
        } else if let bundleID = item.bundleID {
            let data = IconUtils.getAppIconAsPNG(for: bundleID)
            self.fetchedIconData = data
        }
    }
}

private struct ProgressBar: View {
    let percentage: Double
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.06))

                Capsule(style: .continuous)
                    .fill(Color.green.opacity(0.8))
                    .frame(width: max(proxy.size.width * CGFloat(self.percentage / 100), 10))
            }
        }
        .frame(height: 7)
    }
}

private struct PercentageLabel: View {
    let percentage: Double
    
    var body: some View {
        Text("\(Int(self.percentage.rounded()))% of tracked time")
            .font(.kairosCaption2)
            .foregroundColor(.secondary)
    }
}

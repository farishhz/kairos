import Combine
import SwiftUI

// MARK: - Tab Enum

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case appearance
    case analytics

    var id: Self { self }

    var title: String {
        switch self {
        case .general: "General"
        case .appearance: "Appearance"
        case .analytics: "Analytics"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "swatchpalette"
        case .analytics: "chart.bar.xaxis"
        }
    }
}

// MARK: - Version Helper

private enum AppVersion {
    static let displayString: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "Version \(version) (\(build))"
    }()
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var selectedTab: SettingsTab?

    init(initialTab: SettingsTab? = nil) {
        _selectedTab = State(initialValue: initialTab ?? .general)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)
            
            detail
        }
        .frame(minWidth: 860, minHeight: 580)
        // Gunakan satu warna background yang sama untuk seluruh view
        .background(Color.kairosBackground.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .top)
    }

    // MARK: Sidebar
    // - Tidak pakai List agar tidak ada highlight biru bawaan & tidak lag
    // - Tidak pakai clip shape agar sidebar memenuhi tinggi penuh tanpa rounded
    // - Warna background sama dengan kairosBackground agar konsisten
    private var sidebar: some View {
        VStack(spacing: 0) {
            // Spacer menggantikan titlebar area
            Color.clear
                .frame(height: 52)

            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.kairos(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Nav items — pakai VStack biasa, bukan List
            VStack(spacing: 2) {
                ForEach(SettingsTab.allCases) { tab in
                    SettingsSidebarRow(tab: tab, isSelected: selectedTab == tab)
                        .onTapGesture {
                            selectedTab = tab
                        }
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            // Footer versi
            SettingsSidebarFooter()
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .frame(width: 220)
        .frame(maxHeight: .infinity)
        // Samakan warna dengan kairosBackground, atau bisa pakai warna sedikit berbeda
        // tapi tetap satu tone. Jika ingin persis sama, ganti ke Color.kairosBackground
        .background(Color.kairosBackground)
    }

    // MARK: Detail Panel
    private var detail: some View {
        Group {
            switch selectedTab {
            case .general:
                GeneralSettingsPane()
            case .appearance:
                AppearanceSettingsPane()
            case .analytics:
                AnalyticsDashboardView()
            case nil:
                Color.kairosBackground
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.kairosBackground)
        .ignoresSafeArea(.container, edges: .top)
    }
}

// MARK: - Sidebar Row
// Tidak ada lagi List selection, highlight hanya dari background custom ini

private struct SettingsSidebarRow: View {
    let tab: SettingsTab
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: tab.systemImage)
                .font(.kairos(size: 14, weight: .medium))
                .frame(width: 20)
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.55))

            Text(tab.title)
                .font(.kairos(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.65))

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.white.opacity(0.10) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.12) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        // Animasi ringan agar tidak ada lag persepsi saat ganti tab
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Sidebar Footer

private struct SettingsSidebarFooter: View {
    var body: some View {
        Text(AppVersion.displayString)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
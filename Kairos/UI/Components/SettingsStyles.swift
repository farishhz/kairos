import SwiftUI

struct SettingsPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(self.title)
                .font(.kairos(size: 28, weight: .semibold))

            Text(self.subtitle)
                .font(.kairos(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsSectionHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(self.title)
                .font(.kairos(size: 16, weight: .semibold))

            Text(self.subtitle)
                .font(.kairos(size: 12.5, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsSurfaceCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            self.content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.035)))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content)
    {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        HStack(alignment: self.subtitle == nil ? .center : .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.kairos(size: 13.5, weight: .medium))

                if let subtitle = self.subtitle {
                    Text(subtitle)
                        .font(.kairos(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 16)

            self.content()
        }
    }
}

struct SettingsBadge: View {
    let title: String

    var body: some View {
        Text(self.title)
            .font(.kairos(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.06)))
    }
}

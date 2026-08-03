import Foundation
import SwiftUI

struct AnalyticsHeatmapCell: Identifiable, Hashable {
    let id = UUID()
    var date: Date
    var focusSeconds: Double
    var sessionCount: Int = 0
    var intensityLevel: Int

    var displayDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var weekdayAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct AnalyticsBreakdownItem: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var seconds: Double
    var icon: String?
    var bundleID: String?
    var isWebsite: Bool = false
    var iconData: Data?

    var percentage: Double = 0
    var displayDuration: String {
        let minutes = seconds / 60.0
        if minutes >= 60 {
            let hours = Int(minutes / 60)
            let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
            return "\(hours)h \(mins)m"
        }
        return "\(Int(minutes))m"
    }

    enum CodingKeys: String, CodingKey {
        case id, name, seconds, icon, bundleID, isWebsite, percentage
    }

    init(
        name: String,
        seconds: Double,
        icon: String? = nil,
        bundleID: String? = nil,
        iconData: Data? = nil,
        isWebsite: Bool = false,
        percentage: Double = 0
    ) {
        self.name = name
        self.seconds = seconds
        self.icon = icon
        self.bundleID = bundleID
        self.iconData = iconData
        self.isWebsite = isWebsite
        self.percentage = percentage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        seconds = try container.decode(Double.self, forKey: .seconds)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        bundleID = try container.decodeIfPresent(String.self, forKey: .bundleID)
        isWebsite = try container.decodeIfPresent(Bool.self, forKey: .isWebsite) ?? false
        percentage = try container.decodeIfPresent(Double.self, forKey: .percentage) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(seconds, forKey: .seconds)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encodeIfPresent(bundleID, forKey: .bundleID)
        try container.encode(isWebsite, forKey: .isWebsite)
        try container.encode(percentage, forKey: .percentage)
    }
}

struct AnalyticsTimelineEntry: Identifiable, Hashable {
    let id = UUID()
    var startedAt: Date
    var endedAt: Date
    var kind: TimelineEntryKind
    var name: String
    var detail: String?
    var seconds: Double

    enum TimelineEntryKind: String, Codable, Hashable {
        case app
        case website
    }

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startedAt)) - \(formatter.string(from: endedAt))"
    }
}

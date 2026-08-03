import SwiftUI

enum FloatingTheme: String, CaseIterable, Identifiable {
    case obsidian
    case depth
    case moss
    case ember
    case ivory

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .obsidian:
            "Obsidian"
        case .depth:
            "Depth"
        case .moss:
            "Moss"
        case .ember:
            "Ember"
        case .ivory:
            "Ivory"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .obsidian:
            .black
        case .depth:
            Color(red: 15.0 / 255.0, green: 44.0 / 255.0, blue: 63.0 / 255.0)
        case .moss:
            Color(red: 20.0 / 255.0, green: 50.0 / 255.0, blue: 37.0 / 255.0)
        case .ember:
            Color(red: 60.0 / 255.0, green: 30.0 / 255.0, blue: 22.0 / 255.0)
        case .ivory:
            Color(red: 241.0 / 255.0, green: 236.0 / 255.0, blue: 228.0 / 255.0)
        }
    }

    var textColor: Color {
        switch self {
        case .ivory:
            Color(red: 37.0 / 255.0, green: 37.0 / 255.0, blue: 41.0 / 255.0)
        default:
            .white
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .ivory:
            Color.black.opacity(0.58)
        default:
            Color.white.opacity(0.78)
        }
    }

    var borderColor: Color {
        switch self {
        case .ivory:
            Color.black.opacity(0.08)
        case .ember:
            Color(red: 1.0, green: 181.0 / 255.0, blue: 137.0 / 255.0).opacity(0.24)
        case .depth:
            Color(red: 124.0 / 255.0, green: 214.0 / 255.0, blue: 1.0).opacity(0.24)
        case .moss:
            Color(red: 120.0 / 255.0, green: 214.0 / 255.0, blue: 158.0 / 255.0).opacity(0.24)
        case .obsidian:
            Color.white.opacity(0.1)
        }
    }

    var swatchLeadingColor: Color {
        switch self {
        case .obsidian:
            Color(red: 92.0 / 255.0, green: 102.0 / 255.0, blue: 133.0 / 255.0)
        case .depth:
            Color(red: 64.0 / 255.0, green: 189.0 / 255.0, blue: 1.0)
        case .moss:
            Color(red: 88.0 / 255.0, green: 194.0 / 255.0, blue: 131.0 / 255.0)
        case .ember:
            Color(red: 1.0, green: 161.0 / 255.0, blue: 101.0 / 255.0)
        case .ivory:
            Color(red: 1.0, green: 1.0, blue: 1.0)
        }
    }

    var swatchTrailingColor: Color {
        switch self {
        case .obsidian:
            Color(red: 31.0 / 255.0, green: 36.0 / 255.0, blue: 48.0 / 255.0)
        case .depth:
            Color(red: 19.0 / 255.0, green: 82.0 / 255.0, blue: 113.0 / 255.0)
        case .moss:
            Color(red: 29.0 / 255.0, green: 91.0 / 255.0, blue: 62.0 / 255.0)
        case .ember:
            Color(red: 120.0 / 255.0, green: 64.0 / 255.0, blue: 46.0 / 255.0)
        case .ivory:
            Color(red: 220.0 / 255.0, green: 210.0 / 255.0, blue: 195.0 / 255.0)
        }
    }

    static func from(id: String) -> FloatingTheme {
        FloatingTheme(rawValue: id) ?? .obsidian
    }
}

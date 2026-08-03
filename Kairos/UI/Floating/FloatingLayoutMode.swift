import SwiftUI

enum FloatingLayoutMode: String, CaseIterable, Identifiable {
    case timerOnly

    var id: String {
        rawValue
    }

    var title: String {
        "Timer Only"
    }

    var subtitle: String {
        "Minimal floating countdown for deep focus."
    }

    var systemImage: String {
        "timer"
    }

    var requiresImage: Bool {
        false
    }

    var showsTimer: Bool {
        true
    }

    var contentSize: CGSize {
        CGSize(
            width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
            height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)
    }

    static func from(id: String) -> FloatingLayoutMode {
        FloatingLayoutMode(rawValue: id) ?? .timerOnly
    }
}

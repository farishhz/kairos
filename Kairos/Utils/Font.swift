import SwiftUI

extension Font {
    static func kairos(size: CGFloat, weight: Weight = .regular) -> Font {
        .custom("Poppins", size: size).weight(weight)
    }

    static var kairosCaption: Font { .custom("Poppins", size: 11, relativeTo: .caption) }
    static var kairosCaption2: Font { .custom("Poppins", size: 10, relativeTo: .caption2) }
    static var kairosSubheadline: Font { .custom("Poppins", size: 14, relativeTo: .subheadline) }
    static var kairosHeadline: Font { .custom("Poppins", size: 15, relativeTo: .headline) }
    static var kairosTitle2: Font { .custom("Poppins", size: 22, relativeTo: .title2) }
    static var kairosBody: Font { .custom("Poppins", size: 16, relativeTo: .body) }
}

import SwiftUI

/// Three values, no more.
struct InkPalette {
    let paper: Color
    let ink: Color
    let accent: Color
    let isDark: Bool

    /// Flipping the light switch off inverts the entire page.
    var opposite: InkPalette { isDark ? .light : .dark }

    static let light = InkPalette(
        paper:  Color(red: 0xF2 / 255, green: 0xEF / 255, blue: 0xE6 / 255),
        ink:    Color(red: 0x1A / 255, green: 0x1A / 255, blue: 0x1A / 255),
        accent: Color(red: 0xB4 / 255, green: 0x46 / 255, blue: 0x3C / 255),
        isDark: false
    )

    /// Dark mode swaps paper and ink and lifts the accent, or it disappears
    /// against the ink. It is a redraw, not an inversion filter.
    static let dark = InkPalette(
        paper:  Color(red: 0x1A / 255, green: 0x1A / 255, blue: 0x1A / 255),
        ink:    Color(red: 0xF2 / 255, green: 0xEF / 255, blue: 0xE6 / 255),
        accent: Color(red: 0xD9 / 255, green: 0x70 / 255, blue: 0x5F / 255),
        isDark: true
    )

    static func of(_ scheme: ColorScheme) -> InkPalette {
        scheme == .dark ? .dark : .light
    }
}

enum Stroke {
    static let outline: CGFloat = 2.4
    static let detail: CGFloat = 1.6
    static let hatch: CGFloat = 1.1

    /// The second pass of every outline.
    static let secondPassScale: CGFloat = 0.6
    static let secondPassOpacity: Double = 0.55
}

import CoreText
import SwiftUI

enum Typeface {
    static let display = "FrederickatheGreat-Regular"
    static let typewriter = "SpecialElite-Regular"

    /// The target generates its Info.plist, so there is no UIAppFonts array to
    /// add the faces to. Registering with Core Text at launch achieves the same
    /// thing without hand-maintaining a plist.
    static func register() {
        for name in [display, typewriter] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Missing bundled font \(name).ttf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    // The fidget screens lay out in a fixed 393 x 852 design space against
    // drawn artwork, so their type cannot reflow without tearing the drawing
    // away from the labels. Those use the fixed sizes.

    /// Titles and big numbers only — Fredericka falls apart below 24pt.
    static func display(_ size: CGFloat) -> Font { .custom(Typeface.display, fixedSize: size) }
    /// Body text, labels, captions.
    static func typewriter(_ size: CGFloat) -> Font { .custom(Typeface.typewriter, fixedSize: size) }

    // Settings is laid out with real views and can reflow, so it scales with
    // Dynamic Type all the way up to the accessibility sizes.

    static func displayScaled(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(Typeface.display, size: size, relativeTo: style)
    }

    static func typewriterScaled(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(Typeface.typewriter, size: size, relativeTo: style)
    }
}

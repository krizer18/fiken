import SwiftUI
import Observation

/// Everything the settings screen changes. Named Preferences rather than
/// Settings so it cannot be confused with SwiftUI's scene type.
@Observable
final class Preferences {
    enum Paper: String, CaseIterable {
        case light, dark
        var scheme: ColorScheme { self == .dark ? .dark : .light }
        /// Kept apart from `rawValue`, which is the storage key and must never
        /// be translated.
        var label: LocalizedStringKey { self == .dark ? "dark" : "light" }
    }

    enum GoDark: String, CaseIterable {
        case four, ten, never

        var label: LocalizedStringKey {
            switch self {
            case .four: "4s"
            case .ten: "10s"
            case .never: "never"
            }
        }

        var seconds: TimeInterval? {
            switch self {
            case .four: 4
            case .ten: 10
            case .never: nil
            }
        }
    }

    enum Hand: String, CaseIterable {
        case left, right
        var label: LocalizedStringKey { self == .left ? "left" : "right" }
    }

    /// nil follows the system. Picking either one makes it explicit.
    var paper: Paper? { didSet { store(paper?.rawValue, "paper") } }
    var soundOn: Bool { didSet { store(soundOn, "sound") } }
    /// Scales every haptic in the app: 0.4 / 0.7 / 1.0.
    var strength: Float { didSet { store(strength, "strength") } }
    var goDark: GoDark { didSet { store(goDark.rawValue, "goDark") } }
    var hand: Hand { didSet { store(hand.rawValue, "hand") } }
    var boilOn: Bool { didSet { store(boilOn, "boil") } }

    static let strengths: [Float] = [0.4, 0.7, 1.0]

    private let defaults = UserDefaults.standard

    init() {
        let d = UserDefaults.standard
        paper = (d.string(forKey: "paper")).flatMap(Paper.init(rawValue:))
        soundOn = d.object(forKey: "sound") as? Bool ?? false
        strength = d.object(forKey: "strength") as? Float ?? 1.0
        goDark = (d.string(forKey: "goDark")).flatMap(GoDark.init(rawValue:)) ?? .never
        hand = (d.string(forKey: "hand")).flatMap(Hand.init(rawValue:)) ?? .right
        boilOn = d.object(forKey: "boil") as? Bool ?? true
    }

    private func store(_ value: Any?, _ key: String) {
        if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
    }

    /// Which of the two is circled right now, given what the system is doing.
    func effectivePaper(for scheme: ColorScheme) -> Paper {
        paper ?? (scheme == .dark ? .dark : .light)
    }
}

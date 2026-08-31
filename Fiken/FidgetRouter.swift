import SwiftUI
import Observation

/// Which fidget is on screen, and whether the picker is showing.
@Observable
final class FidgetRouter {
    enum Fidget: CaseIterable, Identifiable {
        // Declaration order is the order the picker lists them in.
        case bubbleWrap
        case spinner
        case zipper
        case detentDial
        case lightSwitch
        case glass
        case massage

        var id: Self { self }

        var title: LocalizedStringKey {
            switch self {
            case .lightSwitch: "Light switch"
            case .spinner: "Fidget spinner"
            case .massage: "Finger massage"
            case .detentDial: "Detent dial"
            case .bubbleWrap: "Bubble wrap"
            case .zipper: "Zipper"
            case .glass: "Glass"
            }
        }

        /// The one-line hint under each name in the picker.
        var note: LocalizedStringKey {
            switch self {
            case .lightSwitch: "click to flip"
            case .spinner: "flick to spin"
            case .massage: "four fingers down"
            case .detentDial: "rub in a circle"
            case .bubbleWrap: "press anywhere"
            case .zipper: "drag up or down"
            case .glass: "tap anywhere"
            }
        }
    }

    var current: Fidget = .bubbleWrap
    var isPickerOpen = false
}

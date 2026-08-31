import SwiftUI

extension View {
    /// Hands a fidget's whole surface to the user as a direct-touch area.
    ///
    /// Every fidget here is a custom gesture — flick, rub, drag, press. VoiceOver
    /// normally intercepts those to drive its own cursor, which would leave the
    /// app completely unusable without sight. Marking the surface as direct
    /// touch passes the gestures through untouched, and `.silentOnTouch` keeps
    /// VoiceOver quiet while you are using it, so the haptics are what you hear
    /// from the phone rather than a running commentary.
    ///
    /// A haptics-first app is one of the few kinds that a blind user can use
    /// exactly as a sighted one does. This is what makes that true rather than
    /// merely claimed.
    func fidgetSurface(label: Text, hint: Text) -> some View {
        accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityDirectTouch(options: .silentOnTouch)
    }

    func fidgetSurface(label: Text, value: Text, hint: Text) -> some View {
        accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(hint)
            .accessibilityDirectTouch(options: .silentOnTouch)
    }
}

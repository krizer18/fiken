import Foundation
import Observation

/// Infinite in both directions — no start, no end, no zero to wind back to.
/// `angle` only ever accumulates so the ring can turn with your finger; nothing
/// reads it as a value.
@Observable
final class DialState {
    private(set) var angle: Double = 0
    private(set) var isEngaged = false
    /// Signed rotation since the current touch began, for the travel arc.
    private(set) var travel: Double = 0
    /// Where the finger is, in radians, while engaged.
    private(set) var contact: Double = 0

    @ObservationIgnored var onDetent: (() -> Void)?

    /// One per 15° of arc travel.
    @ObservationIgnored private let detent = 15.0 * .pi / 180
    @ObservationIgnored private var accumulated: Double = 0

    func begin(at angle: Double) {
        isEngaged = true
        travel = 0
        accumulated = 0
        contact = angle
    }

    func rotate(by delta: Double, contact newContact: Double) {
        angle += delta
        travel += delta
        contact = newContact
        accumulated += abs(delta)
        while accumulated >= detent {
            accumulated -= detent
            onDetent?()
        }
    }

    func end() {
        isEngaged = false
        accumulated = 0
    }
}

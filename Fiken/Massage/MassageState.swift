import QuartzCore
import Observation

/// The roll.
///
/// The phone has one taptic engine, so the four pads cannot buzz independently.
/// They are sequenced instead — index to little, 40ms apart — and each pad lights
/// as its own tap fires. The vibration is global, but the eye tells the hand
/// where it came from. That illusion is the whole screen, which is why the
/// visual pulse is driven from the same step as the haptic rather than animated
/// alongside it.
@Observable
final class MassageState {
    /// 0...1. Maps straight onto haptic intensity.
    private(set) var level: Double = 0.22
    /// Which pad is firing right now, or nil during the rest between rolls.
    private(set) var activePad: Int?
    private(set) var contacts: Set<Int> = []
    /// Fades to zero over 300ms once all four contacts have been seen.
    private(set) var guideOpacity: Double = 1

    /// Pad index and level. The index lets a caller accent the start of a roll
    /// without firing on all four.
    @ObservationIgnored var onPulse: ((Int, Double) -> Void)?

    /// 40ms between pads, per the brief. Frequency never changes — only
    /// intensity does.
    @ObservationIgnored private let stepInterval: CFTimeInterval = 0.04
    /// Four taps then two steps of rest, so the roll reads as a roll.
    @ObservationIgnored private let stepsPerCycle = 6

    @ObservationIgnored private var isTouching = false
    @ObservationIgnored private var hasLanded = false
    @ObservationIgnored private var step = 0
    @ObservationIgnored private var lastStepTime: CFTimeInterval = 0
    @ObservationIgnored private var lastFrame: CFTimeInterval = 0
    @ObservationIgnored private var link: CADisplayLink?

    func startClock() {
        guard link == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
        lastFrame = 0
    }

    func stopClock() {
        link?.invalidate()
        link = nil
        activePad = nil
    }

    func setLevel(_ value: Double) {
        level = min(1, max(0, value))
    }

    func setContacts(_ pads: Set<Int>, touching: Bool) {
        contacts = pads
        isTouching = touching
        if pads.count >= 4 { hasLanded = true }
        if !touching { activePad = nil }
    }

    @objc private func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        let delta = lastFrame == 0 ? link.duration : now - lastFrame
        lastFrame = now

        // The hand replaces the drawing, so the guide gets out of the way.
        if hasLanded, guideOpacity > 0 {
            guideOpacity = max(0, guideOpacity - delta / 0.3)
        }

        guard isTouching, level > 0.02 else {
            activePad = nil
            return
        }
        guard now - lastStepTime >= stepInterval else { return }
        lastStepTime = now

        step = (step + 1) % stepsPerCycle
        if step < 4 {
            activePad = step
            onPulse?(step, level)
        } else {
            activePad = nil
        }
    }
}

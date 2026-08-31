import QuartzCore
import Observation

/// The lever's throw, on a display link.
///
/// `tilt` runs −1 (OFF, bottom end raised) through 0 (mid-throw) to +1 (ON, top
/// end raised). The stop is at ±1; the spring is deliberately underdamped so the
/// lever whips slightly past it and settles back.
///
/// `onStrike` fires the instant `tilt` crosses the stop — not when the finger
/// lifts. Timing it to the visual rather than to the touch is what sells it.
@Observable
final class LeverPhysics {
    private(set) var tilt: Double = 1
    private(set) var isOn: Bool = true

    @ObservationIgnored var onStrike: ((Bool) -> Void)?

    /// ~4% overshoot and a ~0.3s settle. Tune by thumb.
    @ObservationIgnored var stiffness: Double = 420
    @ObservationIgnored var damping: Double = 29

    @ObservationIgnored private var velocity: Double = 0
    @ObservationIgnored private var target: Double = 1
    @ObservationIgnored private var hasStruck = true
    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private var lastTimestamp: CFTimeInterval = 0

    func startClock() {
        guard link == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
        lastTimestamp = 0
    }

    func stopClock() {
        link?.invalidate()
        link = nil
    }

    /// Throw the lever to its other position. The spring does the travel, so the
    /// strike still lands when the lever arrives rather than when it was asked.
    func toggle() {
        target = isOn ? -1 : 1
        hasStruck = false
    }

    // MARK: - Integration

    @objc private func step(_ link: CADisplayLink) {
        let delta = lastTimestamp == 0 ? link.duration : link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp
        guard delta > 0 else { return }
        guard abs(tilt - target) > 0.0005 || abs(velocity) > 0.01 else { return }

        // Clamped so a dropped frame cannot blow the spring up.
        let dt = min(delta, 1.0 / 30.0)
        velocity += (-stiffness * (tilt - target) - damping * velocity) * dt
        apply(tilt + velocity * dt)

        if abs(tilt - target) < 0.0005, abs(velocity) < 0.01 {
            apply(target)
            velocity = 0
        }
    }

    /// Single funnel for every change to `tilt`, so the stop is detected exactly
    /// once per throw even though the spring oscillates across it on settling.
    private func apply(_ newTilt: Double) {
        let previous = tilt
        tilt = newTilt
        guard !hasStruck else { return }
        let struckTop = newTilt >= 1 && previous < 1
        let struckBottom = newTilt <= -1 && previous > -1
        guard struckTop || struckBottom else { return }
        hasStruck = true
        isOn = newTilt > 0
        onStrike?(isOn)
    }
}

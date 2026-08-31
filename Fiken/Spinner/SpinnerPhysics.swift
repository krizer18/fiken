import QuartzCore
import Observation

/// Spin physics on a display link. The haptic tick is fired from inside the
/// step, on the same thread and in the same frame as the rotation it belongs
/// to — timing it to the visual rather than to the touch is what sells it.
@Observable
final class SpinnerPhysics {
    private(set) var angle: Double = 0        // radians
    private(set) var velocity: Double = 0     // radians per second

    /// Fired every time accumulated rotation crosses a third of a turn, so the
    /// tick rate slows as the spinner winds down and you feel it losing energy.
    @ObservationIgnored var onTick: (() -> Void)?

    /// The brief's `v *= 0.98` each frame, expressed per second so it feels
    /// identical on a 60Hz iPhone 15 and a 120Hz Pro. Tune this by thumb.
    ///
    /// 0.98 bled off almost all the energy in ~5s, which read as the spinner
    /// grinding rather than coasting. 0.995 gives roughly 15s from a hard flick.
    @ObservationIgnored var decayPerFrameAt60: Double = 0.995

    @ObservationIgnored private let tickInterval: Double = 2 * .pi / 3
    /// Above roughly 45Hz the ticks stop resolving as separate events anyway,
    /// and each one costs a pattern and a player to build. A hard flick can
    /// otherwise ask for more than sixty a second.
    @ObservationIgnored private let maxTickRate: Double = 45
    @ObservationIgnored private var lastTickTime: CFTimeInterval = 0
    /// Below this it is turning too slowly to tick at a useful rate — roughly
    /// one tick every six seconds — so it is dead time rather than wind-down.
    @ObservationIgnored private let restThreshold: Double = 0.3
    @ObservationIgnored private var accumulated: Double = 0
    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private var lastTimestamp: CFTimeInterval = 0

    var isSpinning: Bool { abs(velocity) > restThreshold }
    /// Revolutions per minute, for the readout.
    var rpm: Double { abs(velocity) / (2 * .pi) * 60 }

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

    @objc private func step(_ link: CADisplayLink) {
        let delta = lastTimestamp == 0 ? link.duration : link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp
        guard delta > 0, velocity != 0 else { return }

        rotate(by: velocity * delta)
        velocity *= pow(decayPerFrameAt60, delta * 60)
        if abs(velocity) < restThreshold {
            velocity = 0
            accumulated = 0
        }
    }

    /// Advance the spinner and emit any ticks that crossing implies. Used by
    /// both the display link and the drag, so dragging ticks too.
    func rotate(by delta: Double) {
        angle += delta
        accumulated += abs(delta)
        while accumulated >= tickInterval {
            accumulated -= tickInterval
            let now = CACurrentMediaTime()
            guard now - lastTickTime >= 1 / maxTickRate else { continue }
            lastTickTime = now
            onTick?()
        }
    }

    func hold() {
        velocity = 0
    }

    func flick(_ angularVelocity: Double) {
        velocity = angularVelocity
    }
}

import CoreMotion
import QuartzCore
import Observation

/// Navigation is a shake, so there is nothing to aim at. Defeatable from
/// settings — accidental cycling on a train would be maddening.
@Observable
final class ShakeDetector {
    var isEnabled: Bool = true

    @ObservationIgnored var onShake: (() -> Void)?

    @ObservationIgnored private let motion = CMMotionManager()
    @ObservationIgnored private var lastShake: CFTimeInterval = 0

    /// In g. A deliberate flick of the wrist clears this; normal handling and
    /// walking do not.
    @ObservationIgnored private let threshold: Double = 2.2
    /// Debounce, so one shake is one cycle rather than five.
    @ObservationIgnored private let cooldown: CFTimeInterval = 0.9

    func start() {
        guard motion.isAccelerometerAvailable, !motion.isAccelerometerActive else { return }
        motion.accelerometerUpdateInterval = 1.0 / 50.0
        motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data, self.isEnabled else { return }
            let a = data.acceleration
            let magnitude = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
            let now = CACurrentMediaTime()
            guard magnitude > self.threshold, now - self.lastShake > self.cooldown else { return }
            self.lastShake = now
            self.onShake?()
        }
    }

    func stop() {
        motion.stopAccelerometerUpdates()
    }
}

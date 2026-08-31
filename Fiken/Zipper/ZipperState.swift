import QuartzCore
import Observation

/// The slider's position along the tape, and the tick that follows your speed.
///
/// One tick per tooth of travel, so the rate falls out of how fast you drag
/// rather than being computed — which is what makes it track the finger. Capped
/// at 40Hz, the top of the range in the brief; below that it is simply however
/// fast you are moving.
@Observable
final class ZipperState {
    private(set) var slider: CGFloat
    /// Smoothed ticks per second, for the speed marks beside the slider.
    private(set) var rate: Double = 0

    @ObservationIgnored var onTick: (() -> Void)?

    @ObservationIgnored let travel: ClosedRange<CGFloat>
    @ObservationIgnored private let toothPitch: CGFloat = 9
    @ObservationIgnored private let maxRate: Double = 40
    @ObservationIgnored private var accumulated: CGFloat = 0
    @ObservationIgnored private var lastTick: CFTimeInterval = 0

    init(travel: ClosedRange<CGFloat>) {
        self.travel = travel
        self.slider = travel.lowerBound + (travel.upperBound - travel.lowerBound) * 0.55
    }

    func drag(by delta: CGFloat) {
        let previous = slider
        slider = min(travel.upperBound, max(travel.lowerBound, slider + delta))
        let moved = abs(slider - previous)
        guard moved > 0 else { return }

        accumulated += moved
        while accumulated >= toothPitch {
            accumulated -= toothPitch
            let now = CACurrentMediaTime()
            let gap = now - lastTick
            guard gap >= 1.0 / maxRate else { continue }
            // Smoothed so one uneven sample does not make the marks jump.
            rate = rate * 0.7 + min(maxRate, 1.0 / max(gap, 1.0 / maxRate)) * 0.3
            lastTick = now
            onTick?()
        }
    }

    func release() {
        accumulated = 0
        rate = 0
    }
}

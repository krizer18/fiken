import Foundation
import Observation

/// Hands out a new seed at ~8fps. Every wobble and hatch offset in the app
/// derives from it, so the whole drawing breathes together rather than each
/// element shimmering on its own schedule.
///
/// Defeatable from settings: some people find that much motion unpleasant, and
/// it costs battery.
@Observable
final class BoilClock {
    private(set) var seed: UInt64 = 1

    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            isEnabled ? resume() : suspend()
        }
    }

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private let interval: TimeInterval = 1.0 / 8.0

    init(enabled: Bool = true) {
        isEnabled = enabled
        if enabled { resume() }
    }

    private func resume() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.seed &+= 1
        }
        // .common so the paper keeps breathing while a drag is in flight.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func suspend() {
        timer?.invalidate()
        timer = nil
    }

    deinit { timer?.invalidate() }
}

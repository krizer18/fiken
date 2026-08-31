import QuartzCore
import Observation

/// 4 x 6 at 78pt pitch — roughly thumb width, so there is no gap you can land
/// in and miss.
///
/// A popped bubble comes back on its own after a couple of seconds, so the
/// sheet never runs out and there is nothing to reach for. The delay is long
/// enough that a bubble you just popped stays popped under your thumb, and
/// short enough that a sweep across the sheet finds it full again on the way
/// back.
@Observable
final class BubbleSheet {
    static let columns = 4
    static let rows = 6
    static let count = columns * rows

    private(set) var popped: Set<Int> = []

    @ObservationIgnored var onPop: (() -> Void)?

    /// How long a bubble stays popped before it comes back.
    @ObservationIgnored let regrow: TimeInterval = 2

    @ObservationIgnored private var poppedAt: [Int: CFTimeInterval] = [:]
    @ObservationIgnored private var timer: Timer?

    var remaining: Int { Self.count - popped.count }

    func isPopped(_ index: Int) -> Bool { popped.contains(index) }

    /// One haptic per pop, never repeats — a bubble already gone stays silent
    /// until it has grown back.
    func pop(_ index: Int) {
        guard (0..<Self.count).contains(index), !popped.contains(index) else { return }
        popped.insert(index)
        poppedAt[index] = CACurrentMediaTime()
        onPop?()
    }

    func startClock() {
        guard timer == nil else { return }
        // 10Hz is plenty to land a two-second delay, and far cheaper than a
        // display link for something nobody is watching frame by frame.
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.reclaim()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stopClock() {
        timer?.invalidate()
        timer = nil
    }

    private func reclaim() {
        let now = CACurrentMediaTime()
        let due = poppedAt.filter { now - $0.value >= regrow }.map(\.key)
        guard !due.isEmpty else { return }
        for index in due {
            popped.remove(index)
            poppedAt[index] = nil
        }
    }

    deinit { timer?.invalidate() }
}

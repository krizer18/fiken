import SwiftUI
import Observation

/// One impact site: radials walking outward from the point, plus the concentric
/// rings that join them. The rings are what make it read as glass rather than a
/// spider web.
struct Crack {
    let origin: CGPoint
    let radials: [[CGPoint]]
    let branches: [[CGPoint]]
    let rings: [[CGPoint]]
}

@Observable
final class CrackField {
    /// How many of the most recent cracks stay live — wobbling with the boil and
    /// still fading back. Everything older is baked into one static path.
    static let liveWindow = 6

    private(set) var cracks: [Crack] = []
    /// Older cracks, flattened into a single prebuilt path. Without this, an
    /// unlimited pane would rebuild every crack it has ever drawn on every
    /// boil frame.
    private(set) var settled = Path()
    private(set) var strikes: Int = 0

    @ObservationIgnored private var counter: UInt64 = 0

    @discardableResult
    func strike(at point: CGPoint, in pane: CGRect) -> Bool {
        guard pane.contains(point) else { return false }
        counter &+= 1
        strikes += 1
        cracks.append(Self.make(at: point, in: pane, seed: counter &* 7717 &+ 31))
        while cracks.count > Self.liveWindow {
            bake(cracks.removeFirst())
        }
        return true
    }

    func reset() {
        cracks.removeAll()
        settled = Path()
        strikes = 0
    }

    /// Wobble once, with a fixed seed, and keep the result. These are faint
    /// enough by now that they have no business still breathing.
    private func bake(_ crack: Crack) {
        var seed: UInt64 = 9001
        for run in crack.radials + crack.branches {
            settled.addPath(Sketch.path(Sketch.wobbled(run, seed: seed), closed: false))
            seed &+= 7
        }
        for ring in crack.rings {
            settled.addPath(Sketch.path(Sketch.wobbled(ring, seed: seed), closed: true))
            seed &+= 7
        }
    }

    /// Walk outward with small angle jitter, hang branches off the radials,
    /// then join everything with three irregular rings.
    private static func make(at origin: CGPoint, in pane: CGRect, seed: UInt64) -> Crack {
        var rng = SeededRNG(seed: seed)
        let spokes = 11 + Int(rng.unit() * 3)

        var radials: [[CGPoint]] = []
        for index in 0..<spokes {
            var angle = Double(index) / Double(spokes) * 2 * .pi + Double(rng.signedUnit()) * 0.2
            var point = origin
            var walked: CGFloat = 0
            var path = [point]
            while pane.insetBy(dx: -4, dy: -4).contains(point), walked < 900 {
                angle += Double(rng.signedUnit()) * 0.15
                let step = 16 + rng.unit() * 12
                point = CGPoint(x: point.x + cos(angle) * step, y: point.y + sin(angle) * step)
                path.append(point)
                walked += step
            }
            radials.append(path)
        }

        // A few forks, so it does not read as a perfect star.
        var branches: [[CGPoint]] = []
        for radial in radials where rng.unit() < 0.55 {
            guard radial.count > 4 else { continue }
            let start = 2 + Int(rng.unit() * CGFloat(radial.count - 3))
            var point = radial[start]
            var angle = atan2(point.y - radial[start - 1].y, point.x - radial[start - 1].x)
            angle += Double(rng.signedUnit()) * 0.6 + (rng.unit() < 0.5 ? 0.45 : -0.45)
            var path = [point]
            var walked: CGFloat = 0
            let reach = 40 + rng.unit() * 90
            while pane.contains(point), walked < reach {
                angle += Double(rng.signedUnit()) * 0.2
                let step = 14 + rng.unit() * 10
                point = CGPoint(x: point.x + cos(angle) * step, y: point.y + sin(angle) * step)
                path.append(point)
                walked += step
            }
            branches.append(path)
        }

        // Three rings, each hopping between the radials at a fixed depth.
        var rings: [[CGPoint]] = []
        for fraction in [0.28, 0.56, 0.84] {
            var ring: [CGPoint] = []
            for radial in radials {
                guard radial.count > 2 else { continue }
                let index = max(1, min(radial.count - 1,
                                       Int(Double(radial.count - 1) * fraction)))
                let point = radial[index]
                ring.append(CGPoint(x: point.x + rng.signedUnit() * 5,
                                    y: point.y + rng.signedUnit() * 5))
            }
            guard ring.count > 2 else { continue }
            // Sampled along each span, so the smoothing keeps the polygon
            // angular. Left as bare vertices it curves into a soft loop and
            // stops reading as glass.
            var walked: [CGPoint] = []
            for index in ring.indices {
                walked += Sketch.line(from: ring[index],
                                      to: ring[(index + 1) % ring.count], step: 7).dropLast()
            }
            rings.append(walked)
        }

        return Crack(origin: origin, radials: radials, branches: branches, rings: rings)
    }
}

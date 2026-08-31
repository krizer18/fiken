import SwiftUI

/// Straight from the Figma Build panel:
/// hub r52 · hole 32 — lobe r60 at d104 · hole 34 — lobes at −90° 30° 150°
struct SpinnerGeometry {
    var hubRadius: CGFloat = 52
    var hubHole: CGFloat = 32
    var lobeRadius: CGFloat = 60
    var lobeDistance: CGFloat = 104
    var lobeHole: CGFloat = 34
    var lobeAngles: [Double] = [-90, 30, 150].map { $0 * .pi / 180 }

    /// Closest approach of the silhouette to the centre, between two lobes.
    /// Not in the brief — it is the one number the concave blend needs, and it
    /// is what makes the body read as a spinner rather than three loose balls.
    var waist: CGFloat = 76

    /// Furthest ink from centre, for fitting the drawing to the screen.
    var extent: CGFloat { lobeDistance + lobeRadius }

    var lobeCenters: [CGPoint] {
        lobeAngles.map { CGPoint(x: lobeDistance * cos($0), y: lobeDistance * sin($0)) }
    }

    /// The concave fillet blending each adjacent pair of lobes. Solved from the
    /// tangency condition |F − L| = f + lobeRadius, given |F| = f + waist.
    private var fillet: (radius: CGFloat, distance: CGFloat) {
        let R = lobeRadius, D = lobeDistance, w = waist
        let f = (R * R - w * w - D * D + D * w) / (2 * w - D - 2 * R)
        return (f, f + w)
    }

    private var filletCenters: [CGPoint] {
        let (_, distance) = fillet
        return lobeAngles.map { angle in
            let bisector = angle + .pi / Double(lobeAngles.count)   // +60° for three lobes
            return CGPoint(x: distance * cos(bisector), y: distance * sin(bisector))
        }
    }

    /// The outer silhouette as one closed polyline, sampled ready for wobbling.
    func outline(step: CGFloat = Sketch.resampleStep) -> [CGPoint] {
        let (filletRadius, _) = fillet
        let lobes = lobeCenters
        let fillets = filletCenters
        let count = lobeAngles.count

        var points: [CGPoint] = []
        for i in 0..<count {
            let lobe = lobes[i]
            let previousFillet = fillets[(i + count - 1) % count]
            let nextFillet = fillets[i]

            // Tangent points lie on the line joining the two circle centres, so
            // the lobe arc and the fillet arc meet exactly.
            let entry = atan2(previousFillet.y - lobe.y, previousFillet.x - lobe.x)
            let exit = atan2(nextFillet.y - lobe.y, nextFillet.x - lobe.x)
            let sweep = sweepThrough(from: entry, to: exit, containing: lobeAngles[i])
            points += Sketch.arc(center: lobe, radius: lobeRadius,
                                 from: entry, to: entry + sweep, step: step).dropLast()

            let nextLobe = lobes[(i + 1) % count]
            let filletEntry = atan2(lobe.y - nextFillet.y, lobe.x - nextFillet.x)
            let filletExit = atan2(nextLobe.y - nextFillet.y, nextLobe.x - nextFillet.x)
            points += Sketch.arc(center: nextFillet, radius: filletRadius,
                                 from: filletEntry, to: filletEntry + shortWay(from: filletEntry, to: filletExit),
                                 step: step).dropLast()
        }
        return points
    }

    /// The silhouette plus every hole, as one even-odd path — used both to clip
    /// the hatching and to describe the body's fillable area.
    func bodyPath(seed: UInt64) -> Path {
        var path = Sketch.path(Sketch.wobbled(outline(), seed: seed), closed: true)
        path.addPath(Sketch.path(Sketch.wobbled(Sketch.circle(center: .zero, radius: hubRadius),
                                                seed: seed &+ 11), closed: true))
        for (index, center) in lobeCenters.enumerated() {
            path.addPath(Sketch.path(Sketch.wobbled(Sketch.circle(center: center, radius: lobeHole),
                                                    seed: seed &+ UInt64(31 + index)), closed: true))
        }
        return path
    }

    /// Signed sweep from `a0` to `a1` that passes through `target`.
    private func sweepThrough(from a0: Double, to a1: Double, containing target: Double) -> Double {
        var forward = a1 - a0
        while forward < 0 { forward += 2 * .pi }
        var offset = target - a0
        while offset < 0 { offset += 2 * .pi }
        return offset <= forward ? forward : forward - 2 * .pi
    }

    /// The shorter of the two ways round — for the fillet this is the concave side.
    private func shortWay(from a0: Double, to a1: Double) -> Double {
        var sweep = a1 - a0
        while sweep > .pi { sweep -= 2 * .pi }
        while sweep < -.pi { sweep += 2 * .pi }
        return sweep
    }
}

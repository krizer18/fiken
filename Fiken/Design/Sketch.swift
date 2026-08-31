import SwiftUI

/// The three techniques from the brief — wobble, hatching, double outline —
/// applied through one set of primitives so every screen draws the same way.
enum Sketch {
    /// Resample each path edge roughly this often before wobbling it.
    static let resampleStep: CGFloat = 14
    /// Past about ±1.5 it stops reading as a steady hand and looks broken.
    static let wobbleAmount: CGFloat = 0.9

    // MARK: - Sampled outlines

    static func circle(center: CGPoint, radius: CGFloat, step: CGFloat = resampleStep) -> [CGPoint] {
        let count = max(8, Int((2 * .pi * radius / step).rounded()))
        return (0..<count).map { i in
            let t = Double(i) / Double(count) * 2 * .pi
            return CGPoint(x: center.x + radius * cos(t), y: center.y + radius * sin(t))
        }
    }

    static func arc(center: CGPoint, radius: CGFloat, from a0: Double, to a1: Double,
                    step: CGFloat = resampleStep) -> [CGPoint] {
        let sweep = a1 - a0
        let count = max(2, Int((abs(sweep) * radius / step).rounded()))
        return (0...count).map { i in
            let t = a0 + sweep * Double(i) / Double(count)
            return CGPoint(x: center.x + radius * cos(t), y: center.y + radius * sin(t))
        }
    }

    static func roundedRect(center: CGPoint, size: CGSize, cornerRadius: CGFloat,
                           step: CGFloat = resampleStep) -> [CGPoint] {
        let r = min(cornerRadius, min(size.width, size.height) / 2)
        let left = center.x - size.width / 2, right = center.x + size.width / 2
        let top = center.y - size.height / 2, bottom = center.y + size.height / 2
        var points: [CGPoint] = []
        points += line(from: CGPoint(x: left + r, y: top), to: CGPoint(x: right - r, y: top), step: step).dropLast()
        points += arc(center: CGPoint(x: right - r, y: top + r), radius: r, from: -.pi / 2, to: 0, step: step).dropLast()
        points += line(from: CGPoint(x: right, y: top + r), to: CGPoint(x: right, y: bottom - r), step: step).dropLast()
        points += arc(center: CGPoint(x: right - r, y: bottom - r), radius: r, from: 0, to: .pi / 2, step: step).dropLast()
        points += line(from: CGPoint(x: right - r, y: bottom), to: CGPoint(x: left + r, y: bottom), step: step).dropLast()
        points += arc(center: CGPoint(x: left + r, y: bottom - r), radius: r, from: .pi / 2, to: .pi, step: step).dropLast()
        points += line(from: CGPoint(x: left, y: bottom - r), to: CGPoint(x: left, y: top + r), step: step).dropLast()
        points += arc(center: CGPoint(x: left + r, y: top + r), radius: r, from: .pi, to: 3 * .pi / 2, step: step).dropLast()
        return points
    }

    static func line(from a: CGPoint, to b: CGPoint, step: CGFloat = resampleStep) -> [CGPoint] {
        let dx = b.x - a.x, dy = b.y - a.y
        let count = max(1, Int(((dx * dx + dy * dy).squareRoot() / step).rounded()))
        return (0...count).map { i in
            let t = CGFloat(i) / CGFloat(count)
            return CGPoint(x: a.x + dx * t, y: a.y + dy * t)
        }
    }

    // MARK: - Wobble

    static func wobbled(_ points: [CGPoint], seed: UInt64, amount: CGFloat = wobbleAmount) -> [CGPoint] {
        var rng = SeededRNG(seed: seed)
        return points.map { p in
            CGPoint(x: p.x + rng.signedUnit() * amount, y: p.y + rng.signedUnit() * amount)
        }
    }

    /// Midpoint-quadratic smoothing. Joining the resampled points with straight
    /// segments reads as faceted at these stroke widths; this keeps it pen-like.
    static func path(_ points: [CGPoint], closed: Bool) -> Path {
        var path = Path()
        guard points.count > 2 else {
            guard let first = points.first else { return path }
            path.move(to: first)
            for p in points.dropFirst() { path.addLine(to: p) }
            return path
        }
        if closed {
            path.move(to: mid(points[points.count - 1], points[0]))
            for i in points.indices {
                let current = points[i]
                path.addQuadCurve(to: mid(current, points[(i + 1) % points.count]), control: current)
            }
            path.closeSubpath()
        } else {
            path.move(to: points[0])
            for i in 1..<(points.count - 1) {
                path.addQuadCurve(to: mid(points[i], points[i + 1]), control: points[i])
            }
            path.addLine(to: points[points.count - 1])
        }
        return path
    }

    private static func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    // MARK: - Hatching

    /// Always 45°, never any other angle. Density is the only thing that varies.
    /// `phaseShift` offsets the grid. Passing half the spacing draws a second
    /// pass that interleaves exactly with the first, doubling density without
    /// the moire two independent grids produce.
    static func hatch(covering rect: CGRect, spacing: CGFloat, seed: UInt64,
                      phaseShift: CGFloat = 0) -> Path {
        var rng = SeededRNG(seed: seed)
        // Screen space has y pointing down, so this is the "/" direction
        // the designs use, not "\\".
        let fortyFive = -Double.pi / 4
        let direction = CGVector(dx: cos(fortyFive), dy: sin(fortyFive))
        let normal = CGVector(dx: -direction.dy, dy: direction.dx)

        let corners = [
            CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY)
        ]
        let across = corners.map { $0.x * normal.dx + $0.y * normal.dy }
        let along = corners.map { $0.x * direction.dx + $0.y * direction.dy }
        guard let acrossMin = across.min(), let acrossMax = across.max(),
              let alongMin = along.min(), let alongMax = along.max() else { return Path() }

        // A fresh sub-pixel phase each boil frame, so the hatch breathes with
        // everything else rather than sitting still under a moving outline.
        // Anchored to a global grid, so the same seed lines up across shapes.
        let phase = rng.unit() * spacing + phaseShift
        var offset = ((acrossMin - phase) / spacing).rounded(.down) * spacing + phase
        var combined = Path()
        while offset <= acrossMax + spacing {
            let base = CGPoint(x: normal.dx * offset, y: normal.dy * offset)
            let start = CGPoint(x: base.x + direction.dx * alongMin, y: base.y + direction.dy * alongMin)
            let end = CGPoint(x: base.x + direction.dx * alongMax, y: base.y + direction.dy * alongMax)
            combined.addPath(path(wobbled(line(from: start, to: end), seed: rng.next(), amount: 0.5),
                                  closed: false))
            offset += spacing
        }
        return combined
    }

    static func bounds(of points: [CGPoint]) -> CGRect {
        guard let first = points.first else { return .zero }
        var rect = CGRect(origin: first, size: .zero)
        for p in points.dropFirst() {
            rect = rect.union(CGRect(origin: p, size: .zero))
        }
        return rect
    }
}

extension GraphicsContext {
    /// Every outline is drawn twice — the second pass thinner, lighter and
    /// freshly wobbled. This is what stops it looking like a traced vector.
    func drawOutline(_ points: [CGPoint], closed: Bool, color: Color,
                     width: CGFloat = Stroke.outline, seed: UInt64, opacity: Double = 1) {
        stroke(Sketch.path(Sketch.wobbled(points, seed: seed), closed: closed),
               with: .color(color.opacity(opacity)),
               style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        stroke(Sketch.path(Sketch.wobbled(points, seed: seed &+ 0x9E3779B9), closed: closed),
               with: .color(color.opacity(opacity * Stroke.secondPassOpacity)),
               style: StrokeStyle(lineWidth: width * Stroke.secondPassScale, lineCap: .round, lineJoin: .round))
    }
}

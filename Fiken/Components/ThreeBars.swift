import SwiftUI

/// Settings lives behind three bars in the top-right corner, in the same spot
/// on every screen.
struct ThreeBars: View {
    var seed: UInt64
    var color: Color

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 4
            let gap = (size.height - inset * 2) / 2
            for i in 0..<3 {
                let y = inset + gap * CGFloat(i)
                context.drawOutline(
                    Sketch.line(from: CGPoint(x: inset, y: y),
                                to: CGPoint(x: size.width - inset, y: y)),
                    closed: false,
                    color: color,
                    width: Stroke.outline,
                    seed: seed &+ UInt64(i) &* 977
                )
            }
        }
        .frame(width: 38, height: 26)
        .contentShape(Rectangle())
    }
}

/// The chevron above the spinner. It splays outward and lifts to the accent
/// colour while spinning.
struct Chevron: View {
    var seed: UInt64
    var color: Color
    /// 0 at rest, 1 at full splay.
    var splay: Double

    var body: some View {
        Canvas { context, size in
            let midX = size.width / 2
            let spread = 15 + 10 * splay
            let rise = 15.0

            let apex = CGPoint(x: midX, y: size.height / 2 - rise / 2)
            let left = CGPoint(x: midX - spread, y: size.height / 2 + rise / 2)
            let right = CGPoint(x: midX + spread, y: size.height / 2 + rise / 2)

            // Two separate strokes: joined into one polyline, the midpoint
            // smoothing rounds the apex off into a shallow arc.
            context.drawOutline(Sketch.line(from: left, to: apex), closed: false,
                                color: color, width: Stroke.detail, seed: seed)
            context.drawOutline(Sketch.line(from: apex, to: right), closed: false,
                                color: color, width: Stroke.detail, seed: seed &+ 3)

            // Two short wings that appear only once it is really moving.
            if splay > 0.05 {
                let wing = 16 * splay
                context.drawOutline(
                    Sketch.line(from: CGPoint(x: left.x - wing, y: left.y - wing * 0.55), to: left),
                    closed: false, color: color, width: Stroke.detail, seed: seed &+ 5, opacity: splay)
                context.drawOutline(
                    Sketch.line(from: right, to: CGPoint(x: right.x + wing, y: right.y - wing * 0.55)),
                    closed: false, color: color, width: Stroke.detail, seed: seed &+ 9, opacity: splay)
            }
        }
        .frame(width: 90, height: 34)
        .allowsHitTesting(false)
    }
}

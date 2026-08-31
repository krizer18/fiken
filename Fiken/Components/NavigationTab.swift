import SwiftUI

/// The pull-tab on the left edge. Tapping it opens the fidget picker.
struct NavigationTab: View {
    var seed: UInt64
    var color: Color

    var body: some View {
        Canvas { context, size in
            let outline = tabOutline(in: size)
            let shape = Sketch.path(Sketch.wobbled(outline, seed: seed), closed: true)

            var hatched = context
            hatched.clip(to: shape)
            hatched.stroke(
                Sketch.hatch(covering: CGRect(origin: .zero, size: size).insetBy(dx: -8, dy: -8),
                             spacing: 7, seed: seed &+ 3),
                with: .color(color.opacity(0.8)),
                style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round)
            )

            context.drawOutline(outline, closed: true, color: color,
                                width: Stroke.outline, seed: seed)

            // A chevron pointing out of the edge — pull me. Drawn as two
            // strokes so the smoothing leaves the point sharp.
            let midY = size.height / 2
            let x = size.width - 15
            context.drawOutline(Sketch.line(from: CGPoint(x: x - 5, y: midY - 10),
                                            to: CGPoint(x: x + 5, y: midY), step: 4),
                                closed: false, color: color, width: Stroke.outline, seed: seed &+ 7)
            context.drawOutline(Sketch.line(from: CGPoint(x: x + 5, y: midY),
                                            to: CGPoint(x: x - 5, y: midY + 10), step: 4),
                                closed: false, color: color, width: Stroke.outline, seed: seed &+ 11)
        }
        .frame(width: 34, height: 104)
        .contentShape(Rectangle())
    }

    /// Square against the screen edge, rounded on the side that sticks out.
    private func tabOutline(in size: CGSize) -> [CGPoint] {
        let r: CGFloat = 13
        let left: CGFloat = -10
        let right = size.width - 2
        let top: CGFloat = 2
        let bottom = size.height - 2

        // Sampled tighter than the usual 14: midpoint smoothing rounds a corner
        // by about half a segment, and at 14 that eats the tab's shape entirely.
        let step: CGFloat = 5
        var points: [CGPoint] = []
        points += Sketch.line(from: CGPoint(x: left, y: top),
                              to: CGPoint(x: right - r, y: top), step: step).dropLast()
        points += Sketch.arc(center: CGPoint(x: right - r, y: top + r), radius: r,
                             from: -.pi / 2, to: 0, step: step).dropLast()
        points += Sketch.line(from: CGPoint(x: right, y: top + r),
                              to: CGPoint(x: right, y: bottom - r), step: step).dropLast()
        points += Sketch.arc(center: CGPoint(x: right - r, y: bottom - r), radius: r,
                             from: 0, to: .pi / 2, step: step).dropLast()
        points += Sketch.line(from: CGPoint(x: right - r, y: bottom),
                              to: CGPoint(x: left, y: bottom), step: step).dropLast()
        // The left edge. Without it the loop closes across one long span and the
        // smoothing bows it into a leaf.
        points += Sketch.line(from: CGPoint(x: left, y: bottom),
                              to: CGPoint(x: left, y: top), step: step).dropLast()
        return points
    }
}

/// A name with a hand-drawn ring around it. Selection is circled, not filled —
/// a solid highlight block is the one thing that would make this look like a
/// normal app.
struct CircledLabel: View {
    var text: LocalizedStringKey
    var seed: UInt64
    var color: Color
    var isCircled: Bool
    var font: Font = .typewriter(19)
    /// Drives the padding around the ring; scales with the text.
    var scale: CGFloat = 19

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, scale * 0.52)
            .padding(.vertical, scale * 0.3)
            .background {
                if isCircled {
                    Canvas { context, size in
                        context.drawOutline(ellipse(in: size), closed: true, color: color,
                                            width: Stroke.detail, seed: seed)
                    }
                }
            }
    }

    private func ellipse(in size: CGSize) -> [CGPoint] {
        let rx = size.width / 2, ry = size.height / 2
        let count = max(16, Int((2 * .pi * max(rx, ry) / Sketch.resampleStep).rounded()))
        return (0..<count).map { index in
            let t = Double(index) / Double(count) * 2 * .pi
            return CGPoint(x: rx + rx * cos(t), y: ry + ry * sin(t))
        }
    }
}

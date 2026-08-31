import SwiftUI

/// A drawn switch. Off shows an empty knob on the left, on shows a hatched knob
/// on the right — no fill, no system control.
struct SketchToggle: View {
    var isOn: Bool
    var seed: UInt64
    var color: Color

    @ScaledMetric(relativeTo: .body) private var width: CGFloat = 62
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 30

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 2
            let radius = (size.height - inset * 2) / 2
            let track = Sketch.roundedRect(
                center: CGPoint(x: size.width / 2, y: size.height / 2),
                size: CGSize(width: size.width - inset * 2, height: size.height - inset * 2),
                cornerRadius: radius, step: 6)
            context.drawOutline(track, closed: true, color: color,
                                width: Stroke.outline, seed: seed)

            let knobRadius = radius - 4
            let knobX = isOn ? size.width - inset - radius : inset + radius
            let knob = Sketch.circle(center: CGPoint(x: knobX, y: size.height / 2),
                                     radius: knobRadius, step: 5)
            if isOn {
                var hatched = context
                hatched.clip(to: Sketch.path(Sketch.wobbled(knob, seed: seed &+ 1), closed: true))
                hatched.stroke(
                    Sketch.hatch(covering: CGRect(x: knobX - knobRadius, y: 0,
                                                  width: knobRadius * 2, height: size.height)
                                    .insetBy(dx: -6, dy: -6),
                                 spacing: 4.4, seed: seed &+ 2),
                    with: .color(color.opacity(0.9)),
                    style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round))
            }
            context.drawOutline(knob, closed: true, color: color,
                                width: Stroke.detail, seed: seed &+ 1)
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
    }
}

/// The density swatches from the style sheet, reused as the strength control —
/// darker means tighter, and here it also means stronger.
struct DensitySwatch: View {
    var spacing: CGFloat
    var seed: UInt64
    var color: Color
    var isSelected: Bool

    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 34

    var body: some View {
        Canvas { context, size in
            let square = Sketch.roundedRect(center: CGPoint(x: size.width / 2, y: size.height / 2),
                                            size: CGSize(width: size.width - 4, height: size.height - 4),
                                            cornerRadius: 1.5, step: 6)
            var hatched = context
            hatched.clip(to: Sketch.path(Sketch.wobbled(square, seed: seed), closed: true))
            hatched.stroke(
                Sketch.hatch(covering: CGRect(origin: .zero, size: size).insetBy(dx: -8, dy: -8),
                             spacing: spacing, seed: seed &+ 1),
                with: .color(color.opacity(isSelected ? 0.95 : 0.5)),
                style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round))
            context.drawOutline(square, closed: true, color: color,
                                width: Stroke.detail, seed: seed,
                                opacity: isSelected ? 0.95 : 0.45)
        }
        .frame(width: side, height: side)
        .contentShape(Rectangle())
    }
}

/// A hand-drawn ring, sized to whatever it is placed behind.
struct SketchRing: View {
    var seed: UInt64
    var color: Color

    var body: some View {
        Canvas { context, size in
            let rx = size.width / 2, ry = size.height / 2
            let count = max(18, Int((2 * .pi * max(rx, ry) / Sketch.resampleStep).rounded()))
            let points = (0..<count).map { index -> CGPoint in
                let t = Double(index) / Double(count) * 2 * .pi
                return CGPoint(x: rx + rx * cos(t), y: ry + ry * sin(t))
            }
            context.drawOutline(points, closed: true, color: color,
                                width: Stroke.detail, seed: seed)
        }
    }
}

/// The "Feel it" button: an outlined bar with a hatched block at one end.
struct SketchButton: View {
    var title: LocalizedStringKey
    var seed: UInt64
    var color: Color

    @ScaledMetric(relativeTo: .title2) private var height: CGFloat = 52

    var body: some View {
        Canvas { context, size in
            let frame = Sketch.roundedRect(center: CGPoint(x: size.width / 2, y: size.height / 2),
                                           size: CGSize(width: size.width - 4, height: size.height - 4),
                                           cornerRadius: 2, step: 7)
            let block = CGRect(x: 2, y: 2, width: 38, height: size.height - 4)
            var hatched = context
            hatched.clip(to: Path(block))
            hatched.stroke(
                Sketch.hatch(covering: block.insetBy(dx: -10, dy: -10), spacing: 4.4, seed: seed &+ 1),
                with: .color(color.opacity(0.9)),
                style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round))
            context.drawOutline(frame, closed: true, color: color,
                                width: Stroke.outline, seed: seed)
        }
        .frame(height: height)
        .overlay {
            Text(title)
                .font(.displayScaled(26, relativeTo: .title2))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.horizontal, 48)
        }
        .contentShape(Rectangle())
    }
}

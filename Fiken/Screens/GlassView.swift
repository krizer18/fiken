import SwiftUI

private enum Pane {
    static let width: CGFloat = 393
    static let height: CGFloat = 852

    static let rect = CGRect(x: 41, y: 174, width: 312, height: 453)
    static let counterY: CGFloat = 661
    static let titleY: CGFloat = 747
    static let captionY: CGFloat = 781
}

struct GlassView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(Haptics.self) private var haptics
    @Environment(BoilClock.self) private var boil
    @Environment(ShakeDetector.self) private var shake

    @State private var field = CrackField()
    @State private var scale: CGFloat = 1
    @State private var originX: CGFloat = 0
    @State private var originY: CGFloat = 0

    var body: some View {
        let palette = InkPalette.of(scheme)

        GeometryReader { proxy in
            ZStack {
                palette.paper.ignoresSafeArea()

                Canvas { context, _ in
                    var stage = context
                    stage.translateBy(x: originX, y: originY)
                    stage.scaleBy(x: scale, y: scale)
                    drawPane(in: &stage, palette: palette)

                    var inside = stage
                    inside.clip(to: Path(Pane.rect.insetBy(dx: -2, dy: -2)))
                    inside.stroke(field.settled, with: .color(palette.ink.opacity(0.28)),
                                  style: StrokeStyle(lineWidth: Stroke.detail, lineCap: .round,
                                                     lineJoin: .round))
                    for (index, crack) in field.cracks.enumerated() {
                        // The newest is the darkest; earlier ones settle back.
                        let age = Double(field.cracks.count - 1 - index)
                        let strength = max(0.32, 1 - age * 0.19)
                        draw(crack, in: &inside, palette: palette, strength: strength, index: index)
                    }
                }

                Text(field.strikes == 0
                     ? "tap the pane"
                     : "\(field.strikes) cracks · shake to reset")
                    .font(.typewriter(13))
                    .foregroundStyle(palette.accent)
                    .position(x: proxy.size.width / 2, y: originY + Pane.counterY * scale)

                VStack(spacing: 8) {
                    Text("Glass")
                        .font(.display(28))
                        .foregroundStyle(palette.ink)
                    Text("tap anywhere · it spreads from your finger")
                        .font(.typewriter(13))
                        .foregroundStyle(palette.ink.opacity(0.7))
                }
                .position(x: proxy.size.width / 2,
                          y: originY + (Pane.titleY + Pane.captionY) / 2 * scale)
            }
            .onAppear { measure(proxy.size) }
            .onChange(of: proxy.size) { _, new in measure(new) }
        }
        .contentShape(Rectangle())
        .fidgetSurface(label: Text("Glass"),
                       value: Text("\(field.strikes) cracks"),
                       hint: Text("Tap anywhere to crack it. Shake to reset"))
        .onTapGesture { location in
            guard scale > 0 else { return }
            // Tap anywhere: a tap outside the pane is pulled to its nearest
            // point, so there is still nothing to aim at.
            let raw = CGPoint(x: (location.x - originX) / scale, y: (location.y - originY) / scale)
            let point = CGPoint(x: min(Pane.rect.maxX - 24, max(Pane.rect.minX + 24, raw.x)),
                                y: min(Pane.rect.maxY - 24, max(Pane.rect.minY + 24, raw.y)))
            field.strike(at: point, in: Pane.rect)
            haptics.burst(sound: .crack)
        }
        .onAppear {
            shake.onShake = { field.reset() }
        }
        .onDisappear { shake.onShake = nil }
    }

    private func measure(_ size: CGSize) {
        // Fit the whole design, not just its width — scaling by width alone
        // overflows vertically on shorter phones and clips the captions off.
        scale = min(size.width / Pane.width, size.height / Pane.height)
        originX = (size.width - Pane.width * scale) / 2
        originY = (size.height - Pane.height * scale) / 2
    }

    private func drawPane(in context: inout GraphicsContext, palette: InkPalette) {
        var edge: [CGPoint] = []
        let r = Pane.rect
        edge += Sketch.line(from: CGPoint(x: r.minX, y: r.minY),
                            to: CGPoint(x: r.maxX, y: r.minY)).dropLast()
        edge += Sketch.line(from: CGPoint(x: r.maxX, y: r.minY),
                            to: CGPoint(x: r.maxX, y: r.maxY)).dropLast()
        edge += Sketch.line(from: CGPoint(x: r.maxX, y: r.maxY),
                            to: CGPoint(x: r.minX, y: r.maxY)).dropLast()
        edge += Sketch.line(from: CGPoint(x: r.minX, y: r.maxY),
                            to: CGPoint(x: r.minX, y: r.minY)).dropLast()
        context.drawOutline(edge, closed: true, color: palette.ink,
                            width: Stroke.outline, seed: boil.seed &+ 401)
    }

    private func draw(_ crack: Crack, in context: inout GraphicsContext,
                      palette: InkPalette, strength: Double, index: Int) {
        let base = boil.seed &+ UInt64(index) &* 907

        // Rings first, lighter — they sit behind the radials.
        for (ringIndex, ring) in crack.rings.enumerated() {
            context.drawOutline(ring, closed: true, color: palette.ink,
                                width: Stroke.detail, seed: base &+ UInt64(11 + ringIndex),
                                opacity: strength * 0.42)
        }

        for (branchIndex, branch) in crack.branches.enumerated() {
            context.drawOutline(branch, closed: false, color: palette.ink,
                                width: Stroke.detail, seed: base &+ UInt64(41 + branchIndex),
                                opacity: strength * 0.7)
        }

        for (radialIndex, radial) in crack.radials.enumerated() {
            context.drawOutline(radial, closed: false, color: palette.ink,
                                width: Stroke.outline, seed: base &+ UInt64(71 + radialIndex),
                                opacity: strength)
        }

        // The impact itself.
        for spoke in 0..<3 {
            let angle = Double(spoke) / 3 * .pi
            context.drawOutline(
                Sketch.line(from: CGPoint(x: crack.origin.x - cos(angle) * 9,
                                          y: crack.origin.y - sin(angle) * 9),
                            to: CGPoint(x: crack.origin.x + cos(angle) * 9,
                                        y: crack.origin.y + sin(angle) * 9), step: 5),
                closed: false, color: palette.accent, width: Stroke.outline,
                seed: base &+ UInt64(101 + spoke), opacity: strength)
        }
    }
}

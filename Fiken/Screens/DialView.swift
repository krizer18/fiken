import SwiftUI

/// Measured off the Figma frame, in its 393 x 852 design space.
private enum Dial {
    static let width: CGFloat = 393
    static let height: CGFloat = 852

    static let center = CGPoint(x: 196.5, y: 382)
    static let outerRadius: CGFloat = 149
    static let ringInner: CGFloat = 114
    static let hubRadius: CGFloat = 46

    static let tickInner: CGFloat = 156
    static let tickLength: CGFloat = 11
    static let cardinalLength: CGFloat = 18

    static let contactRadius: CGFloat = 85
    static let contactDot: CGFloat = 13.5
    static let travelRadius: CGFloat = 82
    static let arrowRadius: CGFloat = 178

    static let degreesY: CGFloat = 583
    static let perTickY: CGFloat = 617
    static let titleY: CGFloat = 747
    static let captionY: CGFloat = 781
}

struct DialView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(Haptics.self) private var haptics
    @Environment(BoilClock.self) private var boil

    @State private var dial = DialState()
    @State private var lastTouchAngle: Double?
    @State private var viewSize: CGSize = .zero

    var body: some View {
        let palette = InkPalette.of(scheme)

        GeometryReader { proxy in
            // Fit the whole design, not just its width — scaling by width alone
            // overflows vertically on shorter phones and clips the captions off.
            let scale = min(proxy.size.width / Dial.width, proxy.size.height / Dial.height)
            let originX = (proxy.size.width - Dial.width * scale) / 2
            let originY = (proxy.size.height - Dial.height * scale) / 2

            ZStack {
                palette.paper.ignoresSafeArea()

                Canvas { context, _ in
                    var stage = context
                    stage.translateBy(x: originX, y: originY)
                    stage.scaleBy(x: scale, y: scale)
                    drawRing(in: &stage, palette: palette)
                    drawHub(in: &stage, palette: palette)
                    drawTicks(in: &stage, palette: palette)
                    drawDirections(in: &stage, palette: palette)
                    if dial.isEngaged {
                        drawTravel(in: &stage, palette: palette)
                        drawContact(in: &stage, palette: palette)
                    }
                }

                VStack(spacing: 2) {
                    Text("15°")
                        .font(.display(46))
                        .foregroundStyle(palette.ink)
                    Text("PER TICK")
                        .font(.typewriter(12))
                        .tracking(2)
                        .foregroundStyle(palette.ink.opacity(0.7))
                }
                .position(x: proxy.size.width / 2,
                          y: originY + (Dial.degreesY + Dial.perTickY) / 2 * scale)

                VStack(spacing: 8) {
                    Text("Detent dial")
                        .font(.display(28))
                        .foregroundStyle(palette.ink)
                    Text("rub in a circle · anywhere on screen")
                        .font(.typewriter(13))
                        .foregroundStyle(palette.ink.opacity(0.7))
                }
                .position(x: proxy.size.width / 2,
                          y: originY + (Dial.titleY + Dial.captionY) / 2 * scale)
            }
            .onAppear { viewSize = proxy.size }
            .onChange(of: proxy.size) { _, new in viewSize = new }
        }
        .contentShape(Rectangle())
        .fidgetSurface(label: Text("Detent dial"),
                       hint: Text("Rub in a circle anywhere. One click every fifteen degrees"))
        .gesture(rubGesture)
        .onAppear {
            dial.onDetent = { haptics.transient(intensity: 0.65, sharpness: 0.8, sound: .detent) }
        }
    }

    // MARK: - Gesture

    /// Rub a circle anywhere on screen. Angular tracking about the screen
    /// centre, so the whole screen is the target.
    private var rubGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard viewSize.width > 0 else { return }
                let dx = value.location.x - viewSize.width / 2
                let dy = value.location.y - viewSize.height / 2
                // Too near the centre, a tiny movement is a huge angular change.
                guard (dx * dx + dy * dy).squareRoot() > 36 else { return }

                let angle = atan2(dy, dx)
                guard let previous = lastTouchAngle else {
                    lastTouchAngle = angle
                    dial.begin(at: angle)
                    return
                }
                var delta = angle - previous
                while delta > .pi { delta -= 2 * .pi }
                while delta < -.pi { delta += 2 * .pi }
                lastTouchAngle = angle
                dial.rotate(by: delta, contact: angle)
            }
            .onEnded { _ in
                lastTouchAngle = nil
                dial.end()
            }
    }

    // MARK: - Drawing

    /// The ink rides the ring, so it turns with your finger. The ticks outside
    /// stay put, which is what makes the movement read.
    private func drawRing(in context: inout GraphicsContext, palette: InkPalette) {
        var ring = context
        ring.translateBy(x: Dial.center.x, y: Dial.center.y)
        ring.rotate(by: .radians(dial.angle))

        let outer = Sketch.circle(center: .zero, radius: Dial.outerRadius)
        let inner = Sketch.circle(center: .zero, radius: Dial.ringInner)
        var annulus = Sketch.path(Sketch.wobbled(outer, seed: boil.seed &+ 201), closed: true)
        annulus.addPath(Sketch.path(Sketch.wobbled(inner, seed: boil.seed &+ 203), closed: true))

        var hatched = ring
        hatched.clip(to: annulus, style: FillStyle(eoFill: true))
        hatched.stroke(
            Sketch.hatch(covering: CGRect(x: -Dial.outerRadius, y: -Dial.outerRadius,
                                          width: Dial.outerRadius * 2, height: Dial.outerRadius * 2)
                            .insetBy(dx: -8, dy: -8),
                         spacing: 6, seed: boil.seed &+ 207),
            with: .color(palette.ink.opacity(0.85)),
            style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round))

        ring.drawOutline(outer, closed: true, color: palette.ink,
                         width: Stroke.outline, seed: boil.seed &+ 201)
        ring.drawOutline(inner, closed: true, color: palette.ink,
                         width: Stroke.outline, seed: boil.seed &+ 203)
    }

    private func drawHub(in context: inout GraphicsContext, palette: InkPalette) {
        let hub = Sketch.circle(center: Dial.center, radius: Dial.hubRadius)
        var hatched = context
        hatched.clip(to: Sketch.path(Sketch.wobbled(hub, seed: boil.seed &+ 211), closed: true))
        hatched.stroke(
            Sketch.hatch(covering: CGRect(x: Dial.center.x - Dial.hubRadius,
                                          y: Dial.center.y - Dial.hubRadius,
                                          width: Dial.hubRadius * 2, height: Dial.hubRadius * 2)
                            .insetBy(dx: -8, dy: -8),
                         spacing: 5.4, seed: boil.seed &+ 213),
            with: .color(palette.ink.opacity(0.85)),
            style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round))
        context.drawOutline(hub, closed: true, color: palette.ink,
                            width: Stroke.outline, seed: boil.seed &+ 211)
    }

    /// One tick per detent — 24 of them, longer at the quarters.
    /// Deliberately no marked zero: there is no value here to wind back to.
    private func drawTicks(in context: inout GraphicsContext, palette: InkPalette) {
        for step in 0..<24 {
            let angle = Double(step) * (.pi / 12) - .pi / 2
            let isCardinal = step % 6 == 0
            let length = isCardinal ? Dial.cardinalLength : Dial.tickLength
            let start = CGPoint(x: Dial.center.x + cos(angle) * Dial.tickInner,
                                y: Dial.center.y + sin(angle) * Dial.tickInner)
            let end = CGPoint(x: Dial.center.x + cos(angle) * (Dial.tickInner + length),
                              y: Dial.center.y + sin(angle) * (Dial.tickInner + length))
            context.drawOutline(Sketch.line(from: start, to: end, step: 6), closed: false,
                                color: palette.ink,
                                width: isCardinal ? Stroke.outline : Stroke.detail,
                                seed: boil.seed &+ UInt64(221 + step),
                                opacity: isCardinal ? 0.9 : 0.55)
        }
    }

    /// Both ways, always — the gesture has no preferred direction.
    private func drawDirections(in context: inout GraphicsContext, palette: InkPalette) {
        // Both sweep down towards the foot of the dial, mirrored — measured off
        // the artwork. Screen space, so y is down and increasing angle is clockwise.
        let spans: [(Double, Double)] = [(2.54, 2.08), (0.60, 1.06)]
        for (index, span) in spans.enumerated() {
            let points = Sketch.arc(center: Dial.center, radius: Dial.arrowRadius,
                                    from: span.0, to: span.1, step: 8)
            context.drawOutline(points, closed: false, color: palette.ink,
                                width: Stroke.detail, seed: boil.seed &+ UInt64(251 + index),
                                opacity: 0.45)
            guard let tip = points.last, points.count > 2 else { continue }
            let heading = atan2(tip.y - points[points.count - 2].y, tip.x - points[points.count - 2].x)
            for side in [heading + 2.5, heading - 2.5] {
                context.drawOutline(
                    Sketch.line(from: tip,
                                to: CGPoint(x: tip.x + cos(side) * 13, y: tip.y + sin(side) * 13),
                                step: 6),
                    closed: false, color: palette.ink, width: Stroke.detail,
                    seed: boil.seed &+ UInt64(Int(side * 100).magnitude), opacity: 0.45)
            }
        }
    }

    /// How far this rub has gone. It vanishes on release — it is a trace of the
    /// gesture, not a reading.
    private func drawTravel(in context: inout GraphicsContext, palette: InkPalette) {
        let swept = max(-2 * .pi, min(2 * .pi, dial.travel))
        guard abs(swept) > 0.05 else { return }
        let points = Sketch.arc(center: Dial.center, radius: Dial.travelRadius,
                                from: dial.contact - swept, to: dial.contact, step: 9)
        context.stroke(Sketch.path(Sketch.wobbled(points, seed: boil.seed &+ 271), closed: false),
                       with: .color(palette.accent.opacity(0.75)),
                       style: StrokeStyle(lineWidth: Stroke.detail, lineCap: .round,
                                          dash: [7, 6]))
    }

    private func drawContact(in context: inout GraphicsContext, palette: InkPalette) {
        let point = CGPoint(x: Dial.center.x + cos(dial.contact) * Dial.contactRadius,
                            y: Dial.center.y + sin(dial.contact) * Dial.contactRadius)
        // Small enough to be allowed a solid fill.
        context.fill(Sketch.path(Sketch.wobbled(Sketch.circle(center: point, radius: Dial.contactDot),
                                                seed: boil.seed &+ 281), closed: true),
                     with: .color(palette.accent))
        for (index, radius) in [Dial.contactDot + 4.5, Dial.contactDot + 9].enumerated() {
            context.drawOutline(Sketch.circle(center: point, radius: radius), closed: true,
                                color: palette.accent, width: Stroke.detail,
                                seed: boil.seed &+ UInt64(283 + index),
                                opacity: 0.4 - Double(index) * 0.15)
        }
    }
}

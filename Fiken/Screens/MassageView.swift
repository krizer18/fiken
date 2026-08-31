import SwiftUI

private enum Strip {
    static let width: CGFloat = 393
    static let height: CGFloat = 852

    static let titleY: CGFloat = 131
    static let numberY: CGFloat = 218
    static let labelY: CGFloat = 253

    static let box = CGRect(x: 39.4, y: 296.5, width: 314.6, height: 171.5)
    static let waveCycles: Double = 3.2
    static let maxAmplitude: CGFloat = 72

    static let captionY: CGFloat = 491
    static let ruleY: CGFloat = 543

    /// Measured off the artwork — the pads sit on the arch a resting hand makes.
    /// Mirrored for a left hand; the arch runs the other way.
    static func pads(for hand: Preferences.Hand) -> [(x: CGFloat, y: CGFloat, rx: CGFloat, ry: CGFloat)] {
        guard hand == .left else { return rightPads }
        return rightPads.reversed().map { (width - $0.x, $0.y, $0.rx, $0.ry) }
    }

    static let rightPads: [(x: CGFloat, y: CGFloat, rx: CGFloat, ry: CGFloat)] = [
        (88, 666, 27, 46),
        (161, 645, 31, 50),
        (238, 656, 27, 46),
        (306, 674, 24, 41)
    ]

    static let footTitleY: CGFloat = 772
    static let footCaptionY: CGFloat = 802
}

struct MassageView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(Haptics.self) private var haptics
    @Environment(BoilClock.self) private var boil
    @Environment(Preferences.self) private var prefs

    @State private var massage = MassageState()
    @State private var scale: CGFloat = 1
    @State private var originX: CGFloat = 0
    @State private var originY: CGFloat = 0
    @State private var lastWaveTouchY: CGFloat?

    var body: some View {
        let palette = InkPalette.of(scheme)

        GeometryReader { proxy in
            ZStack {
                palette.paper.ignoresSafeArea()

                Canvas { context, _ in
                    var stage = context
                    stage.translateBy(x: originX, y: originY)
                    stage.scaleBy(x: scale, y: scale)
                    drawBox(in: &stage, palette: palette)
                    drawWave(in: &stage, palette: palette)
                    drawMarker(in: &stage, palette: palette)
                    drawRule(in: &stage, palette: palette)
                    drawPads(in: &stage, palette: palette)
                }

                Text("Massage")
                    .font(.display(30))
                    .foregroundStyle(palette.ink)
                    .position(x: proxy.size.width / 2, y: originY + Strip.titleY * scale)

                VStack(spacing: 2) {
                    Text(Int((massage.level * 100).rounded()), format: .number)
                        .font(.display(46))
                        .foregroundStyle(palette.ink)
                    Text("AMPLITUDE")
                        .font(.typewriter(12))
                        .tracking(2)
                        .foregroundStyle(palette.ink.opacity(0.7))
                }
                .position(x: proxy.size.width / 2,
                          y: originY + (Strip.numberY + Strip.labelY) / 2 * scale)

                Text("drag up or down anywhere on the wave")
                    .font(.typewriter(13))
                    .foregroundStyle(palette.ink.opacity(0.7))
                    .position(x: proxy.size.width / 2, y: originY + Strip.captionY * scale)

                VStack(spacing: 8) {
                    Text(massage.contacts.count >= 4 ? "Four down" : "Rest four fingers")
                        .font(.display(28))
                        .foregroundStyle(palette.ink)
                    Text(massage.contacts.count >= 4
                         ? "rolling index to little"
                         : "guide fades once you land")
                        .font(.typewriter(13))
                        .foregroundStyle(palette.ink.opacity(0.7))
                }
                .position(x: proxy.size.width / 2,
                          y: originY + (Strip.footTitleY + Strip.footCaptionY) / 2 * scale)

                MultiTouchLayer { points in handle(points) }
            }
            .onAppear { measure(proxy.size) }
            .onChange(of: proxy.size) { _, new in measure(new) }
        }
        .fidgetSurface(label: Text("Finger massage"),
                       value: Text("Amplitude \(Int((massage.level * 100).rounded()))"),
                       hint: Text("Drag up or down on the wave to set the strength, then rest four fingers on the pads below"))
        .onAppear {
            massage.onPulse = { pad, level in
                // Amplitude maps straight to intensity; sharpness stays at 0.35
                // so it stays soft rather than buzzy, and frequency never moves.
                haptics.transient(intensity: Float(level), sharpness: 0.35,
                                  // Once per roll, not once per pad.
                                  sound: pad == 0 ? .roll : nil)
            }
            massage.startClock()
        }
        .onDisappear { massage.stopClock() }
    }

    private func measure(_ size: CGSize) {
        // Fit the whole design, not just its width — scaling by width alone
        // overflows vertically on shorter phones and clips the captions off.
        scale = min(size.width / Strip.width, size.height / Strip.height)
        originX = (size.width - Strip.width * scale) / 2
        originY = (size.height - Strip.height * scale) / 2
    }

    // MARK: - Touches

    private func handle(_ points: [CGPoint]) {
        guard scale > 0 else { return }
        let design = points.map {
            CGPoint(x: ($0.x - originX) / scale, y: ($0.y - originY) / scale)
        }

        // A touch inside the strip drives the level, by how far it moves.
        if let wave = design.first(where: { Strip.box.insetBy(dx: -24, dy: -34).contains($0) }) {
            if let previous = lastWaveTouchY {
                massage.setLevel(massage.level - Double((wave.y - previous) / Strip.maxAmplitude))
            }
            lastWaveTouchY = wave.y
        } else {
            lastWaveTouchY = nil
        }

        // Anything below the rule is a fingertip looking for its pad.
        var pads: Set<Int> = []
        for point in design where point.y > Strip.ruleY {
            var best = 0
            var bestDistance = CGFloat.greatestFiniteMagnitude
            for (index, pad) in Strip.pads(for: prefs.hand).enumerated() {
                let dx = point.x - pad.x, dy = point.y - pad.y
                let distance = (dx * dx + dy * dy).squareRoot()
                if distance < bestDistance { bestDistance = distance; best = index }
            }
            if bestDistance < 74 { pads.insert(best) }
        }
        massage.setContacts(pads, touching: !design.isEmpty)
    }

    // MARK: - Drawing

    private func drawBox(in context: inout GraphicsContext, palette: InkPalette) {
        var edge: [CGPoint] = []
        let r = Strip.box
        edge += Sketch.line(from: CGPoint(x: r.minX, y: r.minY), to: CGPoint(x: r.maxX, y: r.minY)).dropLast()
        edge += Sketch.line(from: CGPoint(x: r.maxX, y: r.minY), to: CGPoint(x: r.maxX, y: r.maxY)).dropLast()
        edge += Sketch.line(from: CGPoint(x: r.maxX, y: r.maxY), to: CGPoint(x: r.minX, y: r.maxY)).dropLast()
        edge += Sketch.line(from: CGPoint(x: r.minX, y: r.maxY), to: CGPoint(x: r.minX, y: r.minY)).dropLast()
        context.drawOutline(edge, closed: true, color: palette.ink,
                            width: Stroke.outline, seed: boil.seed &+ 501)

        // The scale down the left inside edge.
        for index in 0..<9 {
            let y = r.minY + 14 + CGFloat(index) * (r.height - 28) / 8
            context.drawOutline(
                Sketch.line(from: CGPoint(x: r.minX + 8, y: y),
                            to: CGPoint(x: r.minX + 20, y: y), step: 6),
                closed: false, color: palette.ink, width: Stroke.detail,
                seed: boil.seed &+ UInt64(511 + index), opacity: 0.55)
        }
    }

    private func waveCurve() -> [CGPoint] {
        let r = Strip.box
        let midY = r.midY
        let amplitude = Strip.maxAmplitude * CGFloat(massage.level)
        let steps = 96
        return (0...steps).map { index in
            let t = Double(index) / Double(steps)
            let x = r.minX + CGFloat(t) * r.width
            let y = midY - amplitude * CGFloat(sin(t * Strip.waveCycles * 2 * .pi))
            return CGPoint(x: x, y: y)
        }
    }

    private func drawWave(in context: inout GraphicsContext, palette: InkPalette) {
        let r = Strip.box
        let curve = waveCurve()

        // The centreline the wave is measured against.
        context.stroke(
            Sketch.path(Sketch.wobbled(Sketch.line(from: CGPoint(x: r.minX + 6, y: r.midY),
                                                   to: CGPoint(x: r.maxX - 6, y: r.midY), step: 12),
                                       seed: boil.seed &+ 521), closed: false),
            with: .color(palette.ink.opacity(0.45)),
            style: StrokeStyle(lineWidth: 1, dash: [4, 5]))

        // Hatch the band between the wave and the centreline; it tightens from
        // 9.5 to 4.5 as the level climbs, so the strip visibly darkens.
        let band = curve + [CGPoint(x: r.maxX, y: r.midY), CGPoint(x: r.minX, y: r.midY)]
        var hatched = context
        hatched.clip(to: Sketch.path(Sketch.wobbled(band, seed: boil.seed &+ 523), closed: true))
        hatched.stroke(
            Sketch.hatch(covering: r.insetBy(dx: -10, dy: -10),
                         spacing: 9.5 - 5 * CGFloat(massage.level), seed: boil.seed &+ 527),
            with: .color(palette.ink.opacity(0.85)),
            style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round))

        context.drawOutline(curve, closed: false, color: palette.ink,
                            width: Stroke.outline, seed: boil.seed &+ 529)
    }

    /// The level marker on the right edge.
    private func drawMarker(in context: inout GraphicsContext, palette: InkPalette) {
        let r = Strip.box
        let y = r.midY - Strip.maxAmplitude * CGFloat(massage.level)
        let tip = CGPoint(x: r.maxX - 8, y: y)
        var arrow = Path()
        arrow.move(to: tip)
        arrow.addLine(to: CGPoint(x: r.maxX + 8, y: y - 8))
        arrow.addLine(to: CGPoint(x: r.maxX + 8, y: y + 8))
        arrow.closeSubpath()
        context.fill(arrow, with: .color(palette.accent))
    }

    private func drawRule(in context: inout GraphicsContext, palette: InkPalette) {
        context.drawOutline(
            Sketch.line(from: CGPoint(x: Strip.box.minX, y: Strip.ruleY),
                        to: CGPoint(x: Strip.box.maxX, y: Strip.ruleY)),
            closed: false, color: palette.ink, width: Stroke.detail,
            seed: boil.seed &+ 541, opacity: 0.4)
    }

    private func drawPads(in context: inout GraphicsContext, palette: InkPalette) {
        for (index, pad) in Strip.pads(for: prefs.hand).enumerated() {
            let center = CGPoint(x: pad.x, y: pad.y)
            let seed = boil.seed &+ UInt64(551 + index &* 3)
            let isDown = massage.contacts.contains(index)
            let isFiring = massage.activePad == index

            let outer = ellipse(center: center, rx: pad.rx, ry: pad.ry)

            if isDown {
                var hatched = context
                hatched.clip(to: Sketch.path(Sketch.wobbled(outer, seed: seed), closed: true))
                hatched.stroke(
                    Sketch.hatch(covering: CGRect(x: center.x - pad.rx, y: center.y - pad.ry,
                                                  width: pad.rx * 2, height: pad.ry * 2)
                                    .insetBy(dx: -8, dy: -8),
                                 // The pad that just fired reads darker, which is
                                 // what tells the hand where the buzz came from.
                                 spacing: isFiring ? 4.2 : 7, seed: seed &+ 1),
                    with: .color(palette.ink.opacity(isFiring ? 0.95 : 0.7)),
                    style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round))

                context.drawOutline(outer, closed: true, color: palette.ink,
                                    width: Stroke.outline, seed: seed)
            } else if massage.guideOpacity > 0.01 {
                // The dashed guide, only until the hand replaces it.
                context.stroke(
                    Sketch.path(Sketch.wobbled(outer, seed: seed), closed: true),
                    with: .color(palette.ink.opacity(0.55 * massage.guideOpacity)),
                    style: StrokeStyle(lineWidth: Stroke.detail, dash: [6, 6]))
            }

            // Two lighter rings inside, as drawn.
            for ring in 0..<2 where !isDown && massage.guideOpacity > 0.01 {
                let shrink = 0.68 - CGFloat(ring) * 0.28
                context.drawOutline(
                    ellipse(center: center, rx: pad.rx * shrink, ry: pad.ry * shrink),
                    closed: true, color: palette.ink, width: Stroke.detail,
                    seed: seed &+ UInt64(2 + ring),
                    opacity: 0.35 * massage.guideOpacity)
            }
        }
    }

    private func ellipse(center: CGPoint, rx: CGFloat, ry: CGFloat) -> [CGPoint] {
        let count = max(16, Int((2 * .pi * max(rx, ry) / Sketch.resampleStep).rounded()))
        return (0..<count).map { index in
            let t = Double(index) / Double(count) * 2 * .pi
            return CGPoint(x: center.x + rx * cos(t), y: center.y + ry * sin(t))
        }
    }
}

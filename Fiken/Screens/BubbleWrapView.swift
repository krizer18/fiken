import SwiftUI

private enum Sheet {
    static let width: CGFloat = 393
    static let height: CGFloat = 852

    static let pitch: CGFloat = 78
    static let radius: CGFloat = 35
    static let centerX: CGFloat = 196.5
    static let centerY: CGFloat = 397

    static let counterY: CGFloat = 676
    static let titleY: CGFloat = 747
    static let captionY: CGFloat = 781

    static func center(of index: Int) -> CGPoint {
        let column = index % BubbleSheet.columns
        let row = index / BubbleSheet.columns
        return CGPoint(
            x: centerX + (CGFloat(column) - CGFloat(BubbleSheet.columns - 1) / 2) * pitch,
            y: centerY + (CGFloat(row) - CGFloat(BubbleSheet.rows - 1) / 2) * pitch
        )
    }
}

struct BubbleWrapView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(Haptics.self) private var haptics
    @Environment(BoilClock.self) private var boil

    @State private var sheet = BubbleSheet()
    @State private var viewSize: CGSize = .zero
    @State private var originX: CGFloat = 0
    @State private var originY: CGFloat = 0
    @State private var scale: CGFloat = 1

    var body: some View {
        let palette = InkPalette.of(scheme)

        GeometryReader { proxy in
            ZStack {
                palette.paper.ignoresSafeArea()

                Canvas { context, _ in
                    var stage = context
                    stage.translateBy(x: originX, y: originY)
                    stage.scaleBy(x: scale, y: scale)
                    for index in 0..<BubbleSheet.count {
                        if sheet.isPopped(index) {
                            drawSkin(in: &stage, index: index, palette: palette)
                        } else {
                            drawBubble(in: &stage, index: index, palette: palette)
                        }
                    }
                }

                Text("\(sheet.remaining) left")
                    .font(.typewriter(13))
                    .foregroundStyle(palette.accent)
                    .position(x: proxy.size.width / 2, y: originY + Sheet.counterY * scale)

                VStack(spacing: 8) {
                    Text("Bubble wrap")
                        .font(.display(28))
                        .foregroundStyle(palette.ink)
                    Text("press anywhere · every spot is a bubble")
                        .font(.typewriter(13))
                        .foregroundStyle(palette.ink.opacity(0.7))
                }
                .position(x: proxy.size.width / 2,
                          y: originY + (Sheet.titleY + Sheet.captionY) / 2 * scale)
            }
            .onAppear { measure(proxy.size) }
            .onChange(of: proxy.size) { _, new in measure(new) }
        }
        .contentShape(Rectangle())
        .fidgetSurface(label: Text("Bubble wrap"),
                       value: Text("\(sheet.remaining) left"),
                       hint: Text("Press or drag across to pop. They come back on their own"))
        // Dragging across the sheet pops everything it crosses, which is the
        // whole point of a sheet of bubble wrap.
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in pop(at: value.location) }
        )
        .onAppear {
            sheet.startClock()
            sheet.onPop = {
                // Brief says 0.9/0.9; the continuous layer under it is what
                // makes a pop feel like something giving way.
                haptics.impact(intensity: 1.0, sharpness: 0.9, body: 0.03, sound: .pop)
            }
        }
        .onDisappear { sheet.stopClock() }
    }

    private func measure(_ size: CGSize) {
        viewSize = size
        // Fit the whole design, not just its width — scaling by width alone
        // overflows vertically on shorter phones and clips the captions off.
        scale = min(size.width / Sheet.width, size.height / Sheet.height)
        originX = (size.width - Sheet.width * scale) / 2
        originY = (size.height - Sheet.height * scale) / 2
    }

    /// Every spot is a bubble: the touch is snapped to the nearest cell rather
    /// than tested against the circles, so there is nothing to miss.
    private func pop(at location: CGPoint) {
        guard scale > 0 else { return }
        let x = (location.x - originX) / scale
        let y = (location.y - originY) / scale
        let column = ((x - Sheet.centerX) / Sheet.pitch + CGFloat(BubbleSheet.columns - 1) / 2)
            .rounded()
        let row = ((y - Sheet.centerY) / Sheet.pitch + CGFloat(BubbleSheet.rows - 1) / 2)
            .rounded()
        guard column >= 0, column < CGFloat(BubbleSheet.columns),
              row >= 0, row < CGFloat(BubbleSheet.rows) else { return }
        sheet.pop(Int(row) * BubbleSheet.columns + Int(column))
    }

    private func drawBubble(in context: inout GraphicsContext, index: Int, palette: InkPalette) {
        let center = Sheet.center(of: index)
        let seed = boil.seed &+ UInt64(index) &* 131
        let outline = Sketch.circle(center: center, radius: Sheet.radius)

        // Hatch everything but a crescent at the top left, which reads as the
        // dome catching light.
        var clip = Sketch.path(Sketch.wobbled(outline, seed: seed), closed: true)
        clip.addPath(Sketch.path(Sketch.wobbled(
            Sketch.circle(center: CGPoint(x: center.x - Sheet.radius * 0.34,
                                          y: center.y - Sheet.radius * 0.36),
                          radius: Sheet.radius * 0.62),
            seed: seed &+ 1), closed: true))

        var hatched = context
        hatched.clip(to: clip, style: FillStyle(eoFill: true))
        hatched.stroke(
            Sketch.hatch(covering: CGRect(x: center.x - Sheet.radius, y: center.y - Sheet.radius,
                                          width: Sheet.radius * 2, height: Sheet.radius * 2)
                            .insetBy(dx: -8, dy: -8),
                         spacing: 6, seed: seed &+ 2),
            with: .color(palette.ink.opacity(0.85)),
            style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round))

        context.drawOutline(outline, closed: true, color: palette.ink,
                            width: Stroke.outline, seed: seed)

        // The highlight tick.
        context.drawOutline(
            Sketch.arc(center: center, radius: Sheet.radius * 0.66,
                       from: -2.5, to: -1.85, step: 5),
            closed: false, color: palette.ink, width: Stroke.detail,
            seed: seed &+ 3, opacity: 0.5)
    }

    /// Slack, wrinkled skin — no dome left to hatch.
    private func drawSkin(in context: inout GraphicsContext, index: Int, palette: InkPalette) {
        let center = Sheet.center(of: index)
        let seed = boil.seed &+ UInt64(index) &* 131 &+ 77
        var rng = SeededRNG(seed: UInt64(index) &* 7919 &+ 13)

        let corners = 9
        var vertices: [CGPoint] = []
        for i in 0..<corners {
            let angle = Double(i) / Double(corners) * 2 * .pi + Double(rng.signedUnit()) * 0.2
            let radius = Sheet.radius * (0.62 + rng.unit() * 0.34)
            vertices.append(CGPoint(x: center.x + cos(angle) * radius,
                                    y: center.y + sin(angle) * radius))
        }
        // Sampled along each edge, so the smoothing leaves the creased corners
        // sharp instead of rounding it back into a circle.
        var points: [CGPoint] = []
        for i in vertices.indices {
            points += Sketch.line(from: vertices[i],
                                  to: vertices[(i + 1) % vertices.count], step: 5).dropLast()
        }
        context.drawOutline(points, closed: true, color: palette.ink,
                            width: Stroke.detail, seed: seed, opacity: 0.5)

        // A few creases where it collapsed.
        for i in 0..<4 {
            let angle = Double(i) / 4 * 2 * .pi + Double(rng.signedUnit()) * 0.5
            let reach = Sheet.radius * (0.2 + rng.unit() * 0.28)
            context.drawOutline(
                Sketch.line(from: CGPoint(x: center.x - cos(angle) * reach * 0.5,
                                          y: center.y - sin(angle) * reach * 0.5),
                            to: CGPoint(x: center.x + cos(angle) * reach,
                                        y: center.y + sin(angle) * reach), step: 6),
                closed: false, color: palette.ink, width: Stroke.detail,
                seed: seed &+ UInt64(i), opacity: 0.42)
        }
    }
}
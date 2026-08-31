import SwiftUI

private enum Tape {
    static let width: CGFloat = 393
    static let height: CGFloat = 852

    static let axis: CGFloat = 196.5
    static let top: CGFloat = 165
    static let bottom: CGFloat = 682
    static let tapeWidth: CGFloat = 60
    /// Half the gap between the two tapes where they are closed.
    static let seam: CGFloat = 3
    /// How far each tape swings out per point above the slider.
    static let splay: CGFloat = 0.142

    static let sliderWidthTop: CGFloat = 56
    static let sliderWidthBottom: CGFloat = 40
    static let sliderHeight: CGFloat = 42

    /// Pitch of the meshed run below the slider. Each tape carries teeth at
    /// twice this, because when closed the two sets interleave.
    static let meshPitch: CGFloat = 13
    static let toothDepth: CGFloat = 6
    static let openToothLength: CGFloat = 15
    static let meshToothLength: CGFloat = 22

    static let markX: CGFloat = 316
    static let titleY: CGFloat = 747
    static let captionY: CGFloat = 781

    static let travel: ClosedRange<CGFloat> = 232...640
}

struct ZipperView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(Haptics.self) private var haptics
    @Environment(BoilClock.self) private var boil

    @State private var zip = ZipperState(travel: Tape.travel)
    @State private var scale: CGFloat = 1
    @State private var originX: CGFloat = 0
    @State private var originY: CGFloat = 0
    @State private var lastY: CGFloat?

    var body: some View {
        let palette = InkPalette.of(scheme)

        GeometryReader { proxy in
            ZStack {
                palette.paper.ignoresSafeArea()

                Canvas { context, _ in
                    var stage = context
                    stage.translateBy(x: originX, y: originY)
                    stage.scaleBy(x: scale, y: scale)
                    drawTape(in: &stage, side: -1, palette: palette)
                    drawTape(in: &stage, side: 1, palette: palette)
                    drawTeeth(in: &stage, palette: palette)
                    drawSlider(in: &stage, palette: palette)
                    drawSpeedMarks(in: &stage, palette: palette)
                }

                VStack(spacing: 8) {
                    Text("Zipper")
                        .font(.display(28))
                        .foregroundStyle(palette.ink)
                    Text("drag up or down · tick rate follows you")
                        .font(.typewriter(13))
                        .foregroundStyle(palette.ink.opacity(0.7))
                }
                .position(x: proxy.size.width / 2,
                          y: originY + (Tape.titleY + Tape.captionY) / 2 * scale)
            }
            .onAppear { measure(proxy.size) }
            .onChange(of: proxy.size) { _, new in measure(new) }
        }
        .contentShape(Rectangle())
        .fidgetSurface(label: Text("Zipper"),
                       hint: Text("Drag up or down to zip and unzip"))
        // Drag along any vertical path — the slider follows the finger's
        // movement, not its position, so you can start anywhere.
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    guard scale > 0 else { return }
                    let y = value.location.y / scale
                    defer { lastY = y }
                    guard let previous = lastY else { return }
                    zip.drag(by: y - previous)
                }
                .onEnded { _ in
                    lastY = nil
                    zip.release()
                }
        )
        .onAppear {
            // Brief says 0.6; lifted because a zip should be felt, and at these
            // rates a transient is all that fits between ticks.
            zip.onTick = { haptics.transient(intensity: 0.85, sharpness: 0.7, sound: .zip) }
        }
    }

    private func measure(_ size: CGSize) {
        // Fit the whole design, not just its width — scaling by width alone
        // overflows vertically on shorter phones and clips the captions off.
        scale = min(size.width / Tape.width, size.height / Tape.height)
        originX = (size.width - Tape.width * scale) / 2
        originY = (size.height - Tape.height * scale) / 2
    }

    /// Inner edge of one tape at a given height: vertical below the slider,
    /// swinging away above it.
    private func innerEdge(at y: CGFloat, side: CGFloat) -> CGFloat {
        let above = max(0, zip.slider - y)
        return Tape.axis + side * (Tape.seam + above * Tape.splay)
    }

    private func drawTape(in context: inout GraphicsContext, side: CGFloat, palette: InkPalette) {
        var inner: [CGPoint] = []
        var y = Tape.top
        while y <= Tape.bottom {
            inner.append(CGPoint(x: innerEdge(at: y, side: side), y: y))
            y += 12
        }
        inner.append(CGPoint(x: innerEdge(at: Tape.bottom, side: side), y: Tape.bottom))

        let outer = inner.reversed().map {
            CGPoint(x: $0.x + side * Tape.tapeWidth, y: $0.y)
        }
        let shape = inner + outer

        var hatched = context
        hatched.clip(to: Sketch.path(Sketch.wobbled(shape, seed: boil.seed &+ 311), closed: true))
        hatched.stroke(
            Sketch.hatch(covering: Sketch.bounds(of: shape).insetBy(dx: -10, dy: -10),
                         spacing: 6.6, seed: boil.seed &+ 313),
            with: .color(palette.ink.opacity(0.85)),
            style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round))

        context.drawOutline(shape, closed: true, color: palette.ink,
                            width: Stroke.outline, seed: boil.seed &+ 311)
    }

    /// Teeth splay above the slider and mesh below it.
    private func drawTeeth(in context: inout GraphicsContext, palette: InkPalette) {
        let sliderTop = zip.slider - Tape.sliderHeight / 2
        let sliderBottom = zip.slider + Tape.sliderHeight / 2

        // Open: each tape's own teeth, on its inner edge.
        var y = Tape.top + 10
        var index = 0
        while y < sliderTop {
            for side in [CGFloat(-1), CGFloat(1)] {
                let edge = innerEdge(at: y, side: side)
                tooth(in: &context,
                      at: CGPoint(x: edge - side * Tape.openToothLength / 2, y: y),
                      length: Tape.openToothLength, palette: palette,
                      seed: boil.seed &+ UInt64(331 + index &* 2) &+ UInt64(side > 0 ? 1 : 0))
            }
            y += Tape.meshPitch * 2
            index += 1
        }

        // Closed: the two sets interleaved into one ladder across the seam.
        y = sliderBottom + 6
        index = 0
        while y < Tape.bottom - 6 {
            let nudge: CGFloat = index % 2 == 0 ? -2.5 : 2.5
            tooth(in: &context, at: CGPoint(x: Tape.axis + nudge, y: y),
                  length: Tape.meshToothLength, palette: palette,
                  seed: boil.seed &+ UInt64(401 + index))
            y += Tape.meshPitch
            index += 1
        }
    }

    private func tooth(in context: inout GraphicsContext, at center: CGPoint,
                       length: CGFloat, palette: InkPalette, seed: UInt64) {
        let shape = Sketch.roundedRect(center: center,
                                       size: CGSize(width: length, height: Tape.toothDepth),
                                       cornerRadius: 1.5, step: 4)
        // Single pass: at this size the usual second outline just fills the
        // tooth in and the ladder turns to mush.
        context.stroke(Sketch.path(Sketch.wobbled(shape, seed: seed), closed: true),
                       with: .color(palette.ink.opacity(0.85)),
                       style: StrokeStyle(lineWidth: Stroke.detail, lineCap: .round,
                                          lineJoin: .round))
    }

    private func drawSlider(in context: inout GraphicsContext, palette: InkPalette) {
        let y = zip.slider
        let halfTop = Tape.sliderWidthTop / 2
        let halfBottom = Tape.sliderWidthBottom / 2
        let top = y - Tape.sliderHeight / 2
        let bottom = y + Tape.sliderHeight / 2

        var shape: [CGPoint] = []
        shape += Sketch.line(from: CGPoint(x: Tape.axis - halfTop, y: top),
                             to: CGPoint(x: Tape.axis + halfTop, y: top), step: 5).dropLast()
        shape += Sketch.line(from: CGPoint(x: Tape.axis + halfTop, y: top),
                             to: CGPoint(x: Tape.axis + halfBottom, y: bottom), step: 5).dropLast()
        shape += Sketch.line(from: CGPoint(x: Tape.axis + halfBottom, y: bottom),
                             to: CGPoint(x: Tape.axis - halfBottom, y: bottom), step: 5).dropLast()
        shape += Sketch.line(from: CGPoint(x: Tape.axis - halfBottom, y: bottom),
                             to: CGPoint(x: Tape.axis - halfTop, y: top), step: 5).dropLast()

        var hatched = context
        hatched.clip(to: Sketch.path(Sketch.wobbled(shape, seed: boil.seed &+ 341), closed: true))
        hatched.stroke(
            Sketch.hatch(covering: Sketch.bounds(of: shape).insetBy(dx: -8, dy: -8),
                         spacing: 5, seed: boil.seed &+ 343),
            with: .color(palette.ink.opacity(0.9)),
            style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round))

        context.drawOutline(shape, closed: true, color: palette.ink,
                            width: Stroke.outline, seed: boil.seed &+ 341)
    }

    /// Accent marks beside the slider that grow with the tick rate.
    private func drawSpeedMarks(in context: inout GraphicsContext, palette: InkPalette) {
        let level = min(1.0, zip.rate / 40)
        guard level > 0.02 else { return }
        for index in 0..<6 {
            let offset = (CGFloat(index) - 2.5) * 17
            let weight = 1 - abs(CGFloat(index) - 2.5) / 3.2
            let length = 12 + 20 * level * weight
            let y = zip.slider + offset
            context.drawOutline(
                Sketch.line(from: CGPoint(x: Tape.markX, y: y),
                            to: CGPoint(x: Tape.markX + length, y: y), step: 6),
                closed: false, color: palette.accent, width: Stroke.detail,
                seed: boil.seed &+ UInt64(351 + index),
                opacity: 0.25 + 0.65 * level * Double(weight))
        }
    }
}

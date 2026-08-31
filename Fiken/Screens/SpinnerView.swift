import SwiftUI

struct SpinnerView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(Haptics.self) private var haptics
    @Environment(BoilClock.self) private var boil

    @State private var physics = SpinnerPhysics()
    @State private var geometry = SpinnerGeometry()

    // Drag tracking, in screen space.
    @State private var lastTouchAngle: Double?
    @State private var lastTouchTime: CFTimeInterval = 0
    @State private var trackedVelocity: Double = 0

    /// Speed at which the ghosts and the lighter hatch reach full effect.
    private let fullSpeed: Double = 26

    var body: some View {
        let palette = InkPalette.of(scheme)
        let speed = min(1, physics.rpm / (fullSpeed / (2 * .pi) * 60))

        GeometryReader { proxy in
            ZStack {
                palette.paper.ignoresSafeArea()

                VStack(spacing: 0) {
                    header(palette: palette, speed: speed)
                    spinner(palette: palette, speed: speed)
                    readout(palette: palette)
                }
            }
            .onAppear { viewSize = proxy.size }
            .onChange(of: proxy.size) { _, new in viewSize = new }
        }
        .contentShape(Rectangle())
        .fidgetSurface(label: Text("Fidget spinner"),
                       value: Text("\(Int(physics.rpm)) RPM"),
                       hint: Text("Flick anywhere to spin it"))
        .gesture(spinGesture)
        .onAppear {
            // Full intensity, over a very short continuous body. A bare
            // transient tops out at 1.0 and still reads thin; the body is what
            // gives each tick weight, and at 20ms it is short enough that the
            // ticks stay separate even when the spinner is running fast.
            physics.onTick = { haptics.impact(intensity: 1.0, sharpness: 0.8, body: 0.02, sound: .tick) }
            physics.startClock()
        }
        .onDisappear { physics.stopClock() }
    }

    // MARK: - Pieces

    private func header(palette: InkPalette, speed: Double) -> some View {
        ZStack(alignment: .top) {
            Chevron(seed: boil.seed,
                    color: speed > 0.02 ? palette.accent : palette.ink.opacity(0.55),
                    splay: speed)
            .padding(.top, 52)
        }
        .padding(.top, 8)
        .frame(height: 108)
    }

    private func spinner(palette: InkPalette, speed: Double) -> some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / (geometry.extent * 2 + 28)
            var stage = context
            stage.translateBy(x: size.width / 2, y: size.height / 2)
            stage.scaleBy(x: scale, y: scale)

            // Ghost strokes trail behind. Outline only — hatched ghosts turn to
            // grey mush at speed.
            let ghosts: [(Double, Double)] = [(-46, 0.16), (-30, 0.26), (-15, 0.42)]
            for (offsetDegrees, opacity) in ghosts where speed > 0.02 {
                var ghost = stage
                ghost.rotate(by: .radians(physics.angle + offsetDegrees * .pi / 180))
                ghost.drawOutline(geometry.outline(), closed: true, color: palette.ink,
                                  width: Stroke.outline, seed: boil.seed &+ 700,
                                  opacity: opacity * speed)
            }

            var body = stage
            body.rotate(by: .radians(physics.angle))
            drawBody(in: &body, palette: palette, speed: speed)

            // The bearing is drawn outside the rotating group and never moves.
            // This is what makes the rotation read as fast.
            drawBearing(in: &stage, palette: palette)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Hatching is generated in the body's own coordinate space, so the ink sits
    /// on the object and turns with it rather than staying pinned to the screen.
    private func drawBody(in context: inout GraphicsContext, palette: InkPalette, speed: Double) {
        let outline = geometry.outline()
        // Spacing opens from 6 to 7.5 while spinning, so the body reads lighter.
        let spacing = 6 + 1.5 * speed

        var hatched = context
        hatched.clip(to: geometry.bodyPath(seed: boil.seed), style: FillStyle(eoFill: true))
        hatched.stroke(
            Sketch.hatch(covering: Sketch.bounds(of: outline).insetBy(dx: -8, dy: -8),
                         spacing: spacing, seed: boil.seed),
            with: .color(palette.ink.opacity(0.85)),
            style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round)
        )

        context.drawOutline(outline, closed: true, color: palette.ink,
                            width: Stroke.outline, seed: boil.seed &+ 3)
        for (index, center) in geometry.lobeCenters.enumerated() {
            context.drawOutline(Sketch.circle(center: center, radius: geometry.lobeHole),
                                closed: true, color: palette.ink,
                                width: Stroke.detail, seed: boil.seed &+ UInt64(41 + index))
        }
    }

    private func drawBearing(in context: inout GraphicsContext, palette: InkPalette) {
        let outer = Sketch.circle(center: .zero, radius: geometry.hubRadius)
        let inner = Sketch.circle(center: .zero, radius: geometry.hubHole)

        var ring = Sketch.path(Sketch.wobbled(outer, seed: boil.seed &+ 61), closed: true)
        ring.addPath(Sketch.path(Sketch.wobbled(inner, seed: boil.seed &+ 67), closed: true))

        var hatched = context
        hatched.clip(to: ring, style: FillStyle(eoFill: true))
        hatched.stroke(
            Sketch.hatch(covering: CGRect(x: -geometry.hubRadius, y: -geometry.hubRadius,
                                          width: geometry.hubRadius * 2, height: geometry.hubRadius * 2),
                         spacing: 5.2, seed: boil.seed &+ 71),
            with: .color(palette.ink.opacity(0.85)),
            style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round)
        )

        context.drawOutline(outer, closed: true, color: palette.ink,
                            width: Stroke.outline, seed: boil.seed &+ 61)
        context.drawOutline(inner, closed: true, color: palette.ink,
                            width: Stroke.detail, seed: boil.seed &+ 67)
    }

    private func readout(palette: InkPalette) -> some View {
        VStack(spacing: 2) {
            Text(physics.rpm < 1 ? "0" : rpmFormatter.string(from: NSNumber(value: Int(physics.rpm))) ?? "0")
                .font(.display(56))
                .foregroundStyle(palette.ink)
            Text("RPM")
                .font(.typewriter(12))
                .tracking(2)
                .foregroundStyle(palette.ink.opacity(0.7))
                .padding(.bottom, 22)

            Text(physics.isSpinning ? "Spinning" : "At rest")
                .font(.display(28))
                .foregroundStyle(palette.ink)
            Text(physics.isSpinning ? "tick on every lobe at twelve" : "flick to spin")
                .font(.typewriter(13))
                .foregroundStyle(palette.ink.opacity(0.7))
        }
        .padding(.bottom, 48)
    }

    // MARK: - Gesture

    /// Angular tracking about the screen centre, so a flick anywhere works and
    /// there is nothing to aim at.
    private var spinGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard viewSize.width > 0 else { return }
                let dx = value.location.x - viewSize.width / 2
                let dy = value.location.y - viewSize.height / 2
                // Near the centre a small movement is a huge angular change, so
                // ignore touches that land there rather than let it explode.
                guard (dx * dx + dy * dy).squareRoot() > 36 else { return }

                let angle = atan2(dy, dx)
                let now = CACurrentMediaTime()
                defer { lastTouchAngle = angle; lastTouchTime = now }

                guard let previous = lastTouchAngle else {
                    physics.hold()
                    trackedVelocity = 0
                    return
                }
                var delta = angle - previous
                while delta > .pi { delta -= 2 * .pi }
                while delta < -.pi { delta += 2 * .pi }

                physics.rotate(by: delta)
                let elapsed = now - lastTouchTime
                if elapsed > 0 {
                    // Smoothed, so one jittery sample cannot define the throw.
                    trackedVelocity = trackedVelocity * 0.6 + (delta / elapsed) * 0.4
                }
            }
            .onEnded { _ in
                physics.flick(trackedVelocity)
                lastTouchAngle = nil
                trackedVelocity = 0
            }
    }

    @State private var viewSize: CGSize = .zero

    private var rpmFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }
}

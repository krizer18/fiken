import SwiftUI

/// Everything is positioned in the Figma design space (393 × 852) and scaled to
/// the real screen, so the proportions come straight off the file.
private enum Design {
    static let width: CGFloat = 393
    static let height: CGFloat = 852

    static let plateCenter = CGPoint(x: 196.5, y: 426)
    static let plateSize = CGSize(width: 162.9, height: 322.1)
    static let plateBorder: CGFloat = 13.2
    static let plateCorner: CGFloat = 12

    static let screwRadius: CGFloat = 7
    static let screwTopY: CGFloat = 296.4
    static let screwBottomY: CGFloat = 556.4

    static let leverSize = CGSize(width: 62.6, height: 160.7)
    static let leverCorner: CGFloat = 9
    /// Measured off the artwork: gap from the raised end, the visible end-face
    /// band, then the hatched slope running away from it.
    static let endGap: CGFloat = 10
    static let endFace: CGFloat = 21.6
    static let shadow: CGFloat = 61

    static let onLabelY: CGFloat = 325.5
    static let offLabelY: CGFloat = 527.5
    static let titleY: CGFloat = 172
    static let stateTitleY: CGFloat = 702
    static let captionY: CGFloat = 742
}

struct LightSwitchView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(Haptics.self) private var haptics
    @Environment(BoilClock.self) private var boil

    @State private var lever = LeverPhysics()

    var body: some View {
        // The page keeps its colour mode; only the lever and the labels change.
        let palette = InkPalette.of(scheme)

        GeometryReader { proxy in
            // Fit the whole design, not just its width — scaling by width alone
            // overflows vertically on shorter phones and clips the captions off.
            let scale = min(proxy.size.width / Design.width, proxy.size.height / Design.height)
            let originX = (proxy.size.width - Design.width * scale) / 2
            let originY = (proxy.size.height - Design.height * scale) / 2

            ZStack {
                palette.paper.ignoresSafeArea()

                Canvas { context, size in
                    var stage = context
                    stage.translateBy(x: originX, y: originY)
                    stage.scaleBy(x: scale, y: scale)
                    drawPlate(in: &stage, palette: palette)
                    drawLever(in: &stage, palette: palette)
                    _ = size
                }

                label("ON", at: Design.onLabelY, active: lever.isOn,
                      palette: palette, scale: scale, originY: originY,
                      centreX: proxy.size.width / 2)
                label("OFF", at: Design.offLabelY, active: !lever.isOn,
                      palette: palette, scale: scale, originY: originY,
                      centreX: proxy.size.width / 2)

                Text("Click Away")
                    .font(.display(34))
                    .foregroundStyle(palette.ink)
                    .position(x: proxy.size.width / 2, y: originY + Design.titleY * scale)

                VStack(spacing: 8) {
                    Text(lever.isOn ? "Lights on" : "Lights out")
                        .font(.display(28))
                        .foregroundStyle(palette.ink)
                    Text("click anywhere to flip")
                        .font(.typewriter(13))
                        .foregroundStyle(palette.ink.opacity(0.7))
                }
                .position(x: proxy.size.width / 2, y: originY + Design.stateTitleY * scale)
            }
        }
        .contentShape(Rectangle())
        .fidgetSurface(label: Text("Light switch"),
                       value: Text(lever.isOn ? "Switched on" : "Switched off"),
                       hint: Text("Tap anywhere to flip the switch"))
        // A click anywhere throws the lever, so there is still nothing to aim at.
        .onTapGesture { lever.toggle() }
        .onAppear {
            lever.onStrike = { _ in
                // One sharp impact, fired the moment the lever hits the stop.
                haptics.impact(intensity: 1.0, sharpness: 0.9, sound: .clack)
            }
            lever.startClock()
        }
        .onDisappear { lever.stopClock() }
    }

    // MARK: - Drawing

    private func drawPlate(in context: inout GraphicsContext, palette: InkPalette) {
        let outer = Sketch.roundedRect(center: Design.plateCenter, size: Design.plateSize,
                                       cornerRadius: Design.plateCorner)
        let innerSize = CGSize(width: Design.plateSize.width - Design.plateBorder * 2,
                               height: Design.plateSize.height - Design.plateBorder * 2)
        let inner = Sketch.roundedRect(center: Design.plateCenter, size: innerSize,
                                       cornerRadius: Design.plateCorner - 3)

        // Hatch only the border ring, not the face — the plate is a frame.
        var ring = Sketch.path(Sketch.wobbled(outer, seed: boil.seed &+ 101), closed: true)
        ring.addPath(Sketch.path(Sketch.wobbled(inner, seed: boil.seed &+ 103), closed: true))

        var hatched = context
        hatched.clip(to: ring, style: FillStyle(eoFill: true))
        hatched.stroke(Sketch.hatch(covering: Sketch.bounds(of: outer).insetBy(dx: -8, dy: -8),
                                    spacing: 6, seed: boil.seed &+ 107),
                       with: .color(palette.ink.opacity(0.85)),
                       style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round))

        context.drawOutline(outer, closed: true, color: palette.ink,
                            width: Stroke.outline, seed: boil.seed &+ 101)
        context.drawOutline(inner, closed: true, color: palette.ink,
                            width: Stroke.detail, seed: boil.seed &+ 103)

        for (index, y) in [Design.screwTopY, Design.screwBottomY].enumerated() {
            let center = CGPoint(x: Design.plateCenter.x, y: y)
            let seed = boil.seed &+ UInt64(113 + index * 2)
            context.drawOutline(Sketch.circle(center: center, radius: Design.screwRadius),
                                closed: true, color: palette.ink, width: Stroke.detail, seed: seed)
            // The slot.
            let reach = Design.screwRadius * 0.72
            context.drawOutline(Sketch.line(from: CGPoint(x: center.x - reach, y: center.y + reach),
                                            to: CGPoint(x: center.x + reach, y: center.y - reach)),
                                closed: false, color: palette.ink, width: Stroke.detail, seed: seed &+ 1)
        }
    }

    /// The receding face. Denser than the plate border, so the two faces of the
    /// lever separate at a glance.
    private let shadeSpacing: CGFloat = 5.0

    /// The lever reads as two faces meeting at a fold: the raised one is clean
    /// paper, the one angling away is hatched. Hatching the whole lever — which
    /// is what the artwork does — leaves both states looking the same.
    private func drawLever(in context: inout GraphicsContext, palette: InkPalette) {
        let tilt = lever.tilt
        let outline = Sketch.roundedRect(center: Design.plateCenter, size: Design.leverSize,
                                         cornerRadius: Design.leverCorner)
        let body = Sketch.path(Sketch.wobbled(outline, seed: boil.seed &+ 131), closed: true)
        let bounds = Sketch.bounds(of: outline)

        // The fold travels from centre out towards whichever end is raised.
        let fold = bounds.midY - bounds.height * 0.22 * tilt
        let receding = tilt >= 0
            ? CGRect(x: bounds.minX, y: fold, width: bounds.width, height: bounds.maxY - fold)
            : CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: fold - bounds.minY)

        var shaded = context
        shaded.clip(to: body)
        shaded.clip(to: Path(receding))
        shaded.stroke(Sketch.hatch(covering: receding.insetBy(dx: -10, dy: -10),
                                   spacing: shadeSpacing, seed: boil.seed &+ 137),
                      with: .color(palette.ink.opacity(0.9)),
                      style: StrokeStyle(lineWidth: Stroke.hatch, lineCap: .round))

        // The fold itself, at outline weight so it holds against the hatching.
        context.drawOutline(Sketch.line(from: CGPoint(x: bounds.minX + 1.5, y: fold),
                                        to: CGPoint(x: bounds.maxX - 1.5, y: fold), step: 6),
                            closed: false, color: palette.ink,
                            width: Stroke.outline, seed: boil.seed &+ 143)

        context.drawOutline(outline, closed: true, color: palette.ink,
                            width: Stroke.outline, seed: boil.seed &+ 131)
    }

    private func label(_ text: LocalizedStringKey, at y: CGFloat, active: Bool,
                       palette: InkPalette, scale: CGFloat, originY: CGFloat,
                       centreX: CGFloat) -> some View {
        Text(text)
            .font(.typewriter(16))
            .tracking(1)
            .foregroundStyle(active ? palette.accent : palette.ink.opacity(0.85))
            .position(x: centreX, y: originY + y * scale)
    }
}

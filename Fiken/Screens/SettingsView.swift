import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(Haptics.self) private var haptics
    @Environment(BoilClock.self) private var boil
    @Environment(Preferences.self) private var prefs

    private let margin: CGFloat = 26

    var body: some View {
        let palette = InkPalette.of(scheme)

        ZStack {
            palette.paper.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Settings")
                        .font(.displayScaled(38, relativeTo: .largeTitle))
                        .foregroundStyle(palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.bottom, 10)
                        .accessibilityAddTraits(.isHeader)

                    rule(palette).padding(.bottom, 34)

                    row("Paper", palette: palette) {
                        options(Preferences.Paper.allCases.map { ($0.label, $0) },
                                selected: prefs.effectivePaper(for: scheme),
                                palette: palette) { prefs.paper = $0 }
                    }

                    row("Sound", note: "clicks and pops, off by default", palette: palette) {
                        SketchToggle(isOn: prefs.soundOn, seed: boil.seed &+ 601, color: palette.ink)
                            .onTapGesture { prefs.soundOn.toggle() }
                            .accessibilityLabel(Text("Sound"))
                            .accessibilityValue(Text(prefs.soundOn ? "Switched on" : "Switched off"))
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint(Text("Double tap to turn sound on or off"))
                    }

                    row("Strength", palette: palette) {
                        HStack(spacing: 14) {
                            ForEach(Array(Preferences.strengths.enumerated()), id: \.offset) { index, value in
                                DensitySwatch(spacing: [9.5, 6, 3.6][index],
                                              seed: boil.seed &+ UInt64(611 + index),
                                              color: palette.ink,
                                              isSelected: prefs.strength == value)
                                    .background {
                                        if prefs.strength == value {
                                            SketchRing(seed: boil.seed &+ UInt64(621 + index),
                                                       color: palette.accent)
                                                .padding(-5)
                                        }
                                    }
                                    .onTapGesture { choose(value) }
                                    .accessibilityLabel(strengthLabel(index))
                                    .accessibilityAddTraits(
                                        prefs.strength == value ? [.isButton, .isSelected] : .isButton)
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(Text("Strength"))
                    }

                    row("Go dark", note: "blacks out · let go to bring it back", palette: palette) {
                        options(Preferences.GoDark.allCases.map { ($0.label, $0) },
                                selected: prefs.goDark, palette: palette) { prefs.goDark = $0 }
                    }

                    row("Fingers", palette: palette) {
                        options(Preferences.Hand.allCases.map { ($0.label, $0) },
                                selected: prefs.hand, palette: palette) { prefs.hand = $0 }
                    }

                    // Reduce Motion wins outright: the toggle can only narrow it.
                    row("Paper boil",
                        note: reduceMotion ? "off · Reduce Motion is on"
                                           : "the drawings breathe · costs battery",
                        palette: palette) {
                        SketchToggle(isOn: prefs.boilOn && !reduceMotion,
                                     seed: boil.seed &+ 631, color: palette.ink)
                            .opacity(reduceMotion ? 0.4 : 1)
                            .onTapGesture { if !reduceMotion { prefs.boilOn.toggle() } }
                            .accessibilityLabel(Text("Paper boil"))
                            .accessibilityValue(Text(
                                reduceMotion ? "Off, turned off by Reduce Motion"
                                             : (prefs.boilOn ? "Switched on" : "Switched off")))
                            .accessibilityAddTraits(.isButton)
                    }

                    SketchButton(title: "Feel it", seed: boil.seed &+ 641, color: palette.ink)
                        .onTapGesture(perform: feelIt)
                        .padding(.top, 30)
                        .accessibilityLabel(Text("Feel it"))
                        .accessibilityHint(Text("Plays one of each haptic in the app"))
                        .accessibilityAddTraits(.isButton)

                    Text("Fiken · 1.0")
                        .font(.typewriterScaled(12, relativeTo: .caption))
                        .foregroundStyle(palette.ink.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 26)
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, margin)
                .padding(.top, 40)
            }
        }
    }

    // MARK: - Pieces

    /// Label beside control normally; stacked once the text is at an
    /// accessibility size, where side by side leaves no room for either.
    @ViewBuilder
    private func row<Control: View>(_ title: LocalizedStringKey,
                                    note: LocalizedStringKey? = nil,
                                    palette: InkPalette,
                                    @ViewBuilder control: () -> Control) -> some View {
        let heading = VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.displayScaled(24, relativeTo: .title2))
                .foregroundStyle(palette.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
            if let note {
                Text(note)
                    .font(.typewriterScaled(10, relativeTo: .caption2))
                    .foregroundStyle(palette.ink.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                heading
                control()
            }
            .padding(.bottom, 26)
        } else {
            HStack(alignment: .center) {
                heading
                Spacer(minLength: 12)
                control()
            }
            .frame(minHeight: 56)
            .padding(.bottom, 22)
        }
    }

    /// Selection is circled, not filled — a solid highlight block is the one
    /// thing that would make this look like a normal settings app.
    private func options<Value: Equatable>(_ items: [(LocalizedStringKey, Value)], selected: Value,
                                           palette: InkPalette,
                                           choose: @escaping (Value) -> Void) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                CircledLabel(text: item.0,
                             seed: boil.seed &+ UInt64(661 + index),
                             color: item.1 == selected ? palette.accent : palette.ink.opacity(0.85),
                             isCircled: item.1 == selected,
                             font: .typewriterScaled(17, relativeTo: .body),
                             scale: 17)
                    .onTapGesture { choose(item.1) }
                    .accessibilityAddTraits(item.1 == selected ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    private func rule(_ palette: InkPalette) -> some View {
        Canvas { context, size in
            context.drawOutline(Sketch.line(from: CGPoint(x: 0, y: size.height / 2),
                                            to: CGPoint(x: size.width, y: size.height / 2)),
                                closed: false, color: palette.ink.opacity(0.6),
                                width: Stroke.detail, seed: boil.seed &+ 671)
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }

    private func strengthLabel(_ index: Int) -> Text {
        switch index {
        case 0: Text("Soft")
        case 1: Text("Medium")
        default: Text("Strong")
        }
    }

    private func choose(_ value: Float) {
        prefs.strength = value
        haptics.strength = value
        // Feel the change you just made.
        haptics.impact(intensity: 0.9, sharpness: 0.8, sound: .clack)
    }

    /// One of each kind of haptic in the app, back to back, so strength is
    /// tunable without leaving settings.
    private func feelIt() {
        haptics.swell(duration: 0.45, sound: .swell)
        after(0.55) { haptics.impact(intensity: 1.0, sharpness: 0.9, sound: .clack) }
        after(0.85) { haptics.transient(intensity: 0.63, sharpness: 0.8, sound: .tick) }
        after(1.05) { haptics.taps(4, spacing: 0.04, intensity: 0.7, sharpness: 0.35,
                                   sound: .roll) }
        after(1.40) { haptics.burst(sound: .crack) }
    }

    private func after(_ delay: TimeInterval, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}

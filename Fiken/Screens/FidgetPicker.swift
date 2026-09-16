import SwiftUI

/// Slides in from the left tab. Pick a fidget by name.
struct FidgetPicker: View {
    @Environment(BoilClock.self) private var boil

    var palette: InkPalette
    var current: FidgetRouter.Fidget
    var onSelect: (FidgetRouter.Fidget) -> Void
    var onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            // Tapping off the panel closes it. Deliberately unpainted — nothing
            // in this app gets a solid fill bigger than a thumbprint.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)

            panel
                .frame(width: 268)
                .frame(maxHeight: .infinity)
                .background(alignment: .trailing) {
                    ZStack(alignment: .trailing) {
                        palette.paper
                        Canvas { context, size in
                            context.drawOutline(
                                Sketch.line(from: CGPoint(x: size.width - 1, y: 0),
                                            to: CGPoint(x: size.width - 1, y: size.height)),
                                closed: false, color: palette.ink,
                                width: Stroke.outline, seed: boil.seed &+ 401)
                        }
                    }
                    .ignoresSafeArea()
                }
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Fidgets")
                .font(.display(34))
                .foregroundStyle(palette.ink)
                .padding(.leading, 24)
                .padding(.bottom, 6)

            rule
                .padding(.horizontal, 24)
                .padding(.bottom, 22)

            ForEach(Array(FidgetRouter.Fidget.allCases.enumerated()), id: \.element) { index, fidget in
                Button {
                    onSelect(fidget)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        CircledLabel(text: fidget.title,
                                     seed: boil.seed &+ UInt64(index) &* 37,
                                     color: fidget == current ? palette.accent : palette.ink,
                                     isCircled: fidget == current)
                        Text(fidget.note)
                            .font(.typewriter(12))
                            .foregroundStyle(palette.ink.opacity(0.6))
                            .padding(.leading, 14)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(fidget == current ? [.isButton, .isSelected] : .isButton)
            }

            Spacer()
        }
        .padding(.top, 90)
    }

    private var rule: some View {
        Canvas { context, size in
            context.drawOutline(Sketch.line(from: CGPoint(x: 0, y: size.height / 2),
                                            to: CGPoint(x: size.width, y: size.height / 2)),
                                closed: false, color: palette.ink.opacity(0.7),
                                width: Stroke.detail, seed: boil.seed &+ 409)
        }
        .frame(height: 6)
    }
}

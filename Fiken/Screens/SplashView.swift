import SwiftUI

/// Shown once, on first launch, and never again.
struct SplashView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(BoilClock.self) private var boil

    var onDismiss: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        let palette = InkPalette.of(scheme)

        ZStack {
            palette.paper.ignoresSafeArea()

            VStack {
                Spacer()
                Text("Fiken")
                    .font(.display(96))
                    .foregroundStyle(palette.ink)
                Spacer()
                Chevron(seed: boil.seed, color: palette.ink.opacity(0.75), splay: 0)
                Text("Swipe up to get fidgeting")
                    .font(.typewriter(17))
                    .foregroundStyle(palette.ink.opacity(0.8))
                    .padding(.top, 26)
                    .padding(.bottom, 40)
            }
        }
        .offset(y: dragOffset)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Fiken"))
        .accessibilityHint(Text("Swipe up to start"))
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in dragOffset = min(0, value.translation.height) }
                .onEnded { value in
                    if value.translation.height < -70 {
                        withAnimation(.easeIn(duration: 0.28)) { dragOffset = -1200 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28, execute: onDismiss)
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { dragOffset = 0 }
                    }
                }
        )
    }
}

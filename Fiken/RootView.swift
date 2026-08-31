import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(Haptics.self) private var haptics
    @Environment(BoilClock.self) private var boil
    @Environment(ShakeDetector.self) private var shake
    @Environment(Preferences.self) private var prefs
    @Environment(SoundEngine.self) private var sound

    @State private var router = FidgetRouter()
    @State private var isSettingsOpen = false
    @State private var isBlackedOut = false
    @State private var blackoutWork: DispatchWorkItem?

    /// The opening screen shows once after install, then never again.
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false

    var body: some View {
        let palette = InkPalette.of(scheme)

        ZStack {
            switch router.current {
            case .lightSwitch: LightSwitchView()
            case .spinner: SpinnerView()
            case .massage: MassageView()
            case .detentDial: DialView()
            case .bubbleWrap: BubbleWrapView()
            case .zipper: ZipperView()
            case .glass: GlassView()
            }

            chrome(palette: palette)

            if router.isPickerOpen {
                FidgetPicker(
                    palette: palette,
                    current: router.current,
                    onSelect: { fidget in
                        if fidget != router.current { haptics.swell(duration: 0.45, sound: .swell) }
                        router.current = fidget
                        close()
                    },
                    onDismiss: close
                )
                .transition(reduceMotion ? .opacity : .move(edge: .leading).combined(with: .opacity))
                .zIndex(2)
            }

            if isSettingsOpen {
                SettingsView()
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
                    .zIndex(2.5)
            }

            // Go dark. Never takes touches — the fidget carries on underneath,
            // which is the entire point of blanking it.
            if isBlackedOut {
                Color.black
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .zIndex(4)
            }

            if !hasSeenIntro {
                SplashView {
                    haptics.swell(duration: 0.45, sound: .swell)
                    hasSeenIntro = true
                }
                    .transition(.opacity)
                    .zIndex(5)
            }
        }
        .statusBarHidden()
        .onAppear {
            shake.start()
            applyBoil()
            haptics.strength = prefs.strength
            haptics.sound = sound
            sound.isEnabled = prefs.soundOn
            ContactWatcher.shared.attach()
            ContactWatcher.shared.onChange = { touching in scheduleBlackout(touching) }
        }
        .preferredColorScheme(prefs.paper?.scheme)
        .onChange(of: prefs.soundOn) { _, on in sound.isEnabled = on }
        .onChange(of: reduceMotion) { _, _ in applyBoil() }
        .onChange(of: prefs.boilOn) { _, _ in applyBoil() }
        .onChange(of: prefs.goDark) { _, mode in
            if mode.seconds == nil { wake() }
        }
        .onChange(of: scenePhase) { _, phase in
            // Core Haptics is stopped, and the audio session torn down, when
            // the app backgrounds.
            if phase == .active {
                haptics.wake()
                sound.wake()
            }
        }
    }

    /// Same spot on every screen: bars top-right, navigation tab left edge.
    private func chrome(palette: InkPalette) -> some View {
        ZStack {
            HStack {
                Spacer()
                ThreeBars(seed: boil.seed, color: palette.ink)
                    .padding(.trailing, 22)
                    .accessibilityLabel(Text("Settings"))
                    .accessibilityAddTraits(.isButton)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                            isSettingsOpen.toggle()
                        }
                    }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 8)

            // Above centre, so it clears the spinner's left lobe. Still the
            // same spot on every screen, which is what matters for finding it.
            GeometryReader { proxy in
                NavigationTab(seed: boil.seed, color: palette.ink)
                    .position(x: 17, y: proxy.size.height * 0.3)
                    .accessibilityLabel(Text("Fidgets"))
                    .accessibilityHint(Text("Choose which fidget to use"))
                    .accessibilityAddTraits(.isButton)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                            router.isPickerOpen = true
                        }
                    }
            }
            .opacity(router.isPickerOpen || isSettingsOpen ? 0 : 1)
        }
        .zIndex(3)
    }

    /// The boil is the app's largest motion, so Reduce Motion switches it off
    /// on its own — the manual toggle only ever narrows this, never widens it.
    private func applyBoil() {
        boil.isEnabled = prefs.boilOn && !reduceMotion
    }

    /// Blank after a settled run of contact, and only when "go dark" is set to
    /// 4s or 10s. Letting go brings it straight back.
    private func scheduleBlackout(_ touching: Bool) {
        blackoutWork?.cancel()
        blackoutWork = nil

        guard touching, !isSettingsOpen, !router.isPickerOpen,
              let delay = prefs.goDark.seconds else {
            wake()
            return
        }
        // Already dark and still held: leave it alone. A second finger landing
        // must not restart the countdown or lift the blackout.
        guard !isBlackedOut else { return }

        let work = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.6)) { isBlackedOut = true }
        }
        blackoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func wake() {
        guard isBlackedOut else { return }
        withAnimation(.easeOut(duration: 0.22)) { isBlackedOut = false }
    }

    private func close() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            router.isPickerOpen = false
        }
    }
}

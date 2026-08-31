import SwiftUI

@main
struct FikenApp: App {
    @State private var haptics = Haptics()
    @State private var boil = BoilClock()
    @State private var shake = ShakeDetector()
    @State private var prefs = Preferences()
    @State private var sound = SoundEngine()

    init() {
        Typeface.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(haptics)
                .environment(boil)
                .environment(shake)
                .environment(prefs)
                .environment(sound)
        }
    }
}

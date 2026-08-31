import AVFoundation
import Observation

/// Every sound in Fiken is synthesised at launch, not loaded from a file.
///
/// The drawings are generated rather than drawn once and shipped; the audio
/// works the same way. It costs a few kilobytes of code instead of megabytes of
/// samples, it needs no licensing, and each voice is rendered in several
/// variants so a run of bubble pops sounds like a run of bubbles rather than
/// one sample fired twenty-four times.
///
/// Every voice is noise plus a pitched body. Noise is what makes a sound read
/// as a physical object rather than a synthesiser — a pop without it is a
/// bloop, and a zipper without it is a note. The calm comes from where the
/// pitch sits and how fast it decays, not from removing the noise.
///
/// Voices carry their own roll-off rather than sharing one. The ones that need
/// to sound like something real keep their top end; the ones that repeat
/// fastest, or are meant to soothe, are filtered hard.
@Observable
final class SoundEngine {
    enum Voice: CaseIterable {
        case tick      // spinner
        case clack     // light switch
        case detent    // dial
        case pop       // bubble wrap
        case zip       // zipper
        case crack     // glass
        case roll      // massage
        case swell     // arrival

        /// Sound layers *under* the haptics. The repeating voices — tick, zip,
        /// detent — are quietest, because a sound you hear forty times a second
        /// has to be one you stop noticing.
        var gain: Float {
            switch self {
            case .tick: 0.16
            case .clack: 0.28
            case .detent: 0.19
            case .pop: 0.38
            case .zip: 0.12
            case .crack: 0.50
            case .roll: 0.14
            case .swell: 0.28
            }
        }

        /// Per-voice roll-off. `nil` leaves the voice untouched — used for the
        /// two that were already right, so filtering cannot drift them.
        var cutoff: Double? {
            switch self {
            case .crack, .pop, .clack: nil
            case .zip: 2000
            case .tick: 3000
            case .detent: 2400
            case .roll: 1800
            case .swell: 1200
            }
        }

        /// A stable per-voice seed offset. Deliberately not `hashValue`: that is
        /// seeded per process, so the sounds would come out different on every
        /// launch — and it can be negative, which traps on conversion.
        var seedOffset: UInt64 {
            switch self {
            case .tick: 1
            case .clack: 2
            case .detent: 3
            case .pop: 4
            case .zip: 5
            case .crack: 6
            case .roll: 7
            case .swell: 8
            }
        }

        /// Filename fragments used to find a supplied recording for this voice.
        /// Matching on a fragment rather than a full name means a replacement
        /// can just be dropped in — these files arrive with names like
        /// "dragon-studio-light-switch-382712.mp3".
        var recordingKeywords: [String] {
            switch self {
            case .pop: ["pop", "bubble"]
            case .clack: ["switch"]
            default: []
            }
        }

        /// Pitches to resample a recording to, so a repeated sample does not
        /// sound like a repeated sample. Bubbles vary a lot; a switch is the
        /// same bit of plastic every time, so it barely moves.
        var recordedPitches: [Double] {
            switch self {
            case .pop: [0.92, 0.97, 1.0, 1.04, 1.09, 1.15]
            case .clack: [0.98, 1.0, 1.02]
            default: [1.0]
            }
        }

        /// How many differently-seeded renderings to keep.
        var variants: Int {
            switch self {
            case .pop: 6
            case .tick, .zip, .detent, .crack: 4
            default: 2
            }
        }
    }

    var isEnabled: Bool = false {
        didSet {
            guard isEnabled != oldValue else { return }
            isEnabled ? start() : stop()
        }
    }

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var players: [AVAudioPlayerNode] = []
    @ObservationIgnored private var nextPlayer = 0
    @ObservationIgnored private var banks: [Voice: [AVAudioPCMBuffer]] = [:]
    @ObservationIgnored private var isRunning = false

    private static let sampleRate: Double = 44_100
    /// Eight voices of polyphony — enough for a fast drag across the bubble
    /// sheet without cutting off the pops behind it.
    private static let polyphony = 8

    init() {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: Self.sampleRate,
                                         channels: 1, interleaved: false) else { return }
        for voice in Voice.allCases {
            // A supplied recording wins over synthesis wherever one exists.
            if let recorded = Self.loadRecording(for: voice) {
                banks[voice] = voice.recordedPitches.compactMap { pitch in
                    let shifted = Self.resample(recorded.samples, from: recorded.rate, pitch: pitch)
                    return Self.buffer(Self.normalized(shifted), format: format)
                }
                continue
            }
            banks[voice] = (0..<voice.variants).compactMap { index in
                var raw = Self.render(voice, seed: UInt64(index) &* 7919 &+ 17)
                if let cutoff = voice.cutoff { raw = Self.softened(raw, cutoff: cutoff) }
                return Self.buffer(Self.normalized(raw), format: format)
            }
        }
        for _ in 0..<Self.polyphony {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        engine.mainMixerNode.outputVolume = 0.9
    }

    // MARK: - Lifecycle

    private func start() {
        guard !isRunning else { return }
        do {
            // .ambient with .mixWithOthers: never interrupt whatever the user
            // already has playing, and honour the ring/silent switch. Most
            // people open this next to something else.
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default,
                                                            options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            for player in players { player.play() }
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    private func stop() {
        guard isRunning else { return }
        for player in players { player.stop() }
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        isRunning = false
    }

    /// The audio session is torn down when the app backgrounds.
    func wake() {
        guard isEnabled else { return }
        isRunning = false
        start()
    }

    func play(_ voice: Voice) {
        guard isEnabled, isRunning, let bank = banks[voice], !bank.isEmpty else { return }
        let buffer = bank[Int.random(in: 0..<bank.count)]
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.volume = voice.gain
        // .interrupts so a voice reused mid-tail restarts cleanly rather than
        // queueing behind itself.
        player.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    // MARK: - Recorded sources

    private static let audioExtensions = ["mp3", "wav", "m4a", "aiff", "caf"]

    /// Finds a supplied recording by searching the bundle, rather than depending
    /// on an exact filename. A hardcoded name that no longer matches falls back
    /// to synthesis silently, which looks like nothing happened.
    private static func loadRecording(for voice: Voice) -> (samples: [Float], rate: Double)? {
        let keywords = voice.recordingKeywords
        guard !keywords.isEmpty else { return nil }
        for ext in audioExtensions {
            let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let name = url.deletingPathExtension().lastPathComponent.lowercased()
                guard keywords.contains(where: { name.contains($0) }) else { continue }
                if let loaded = load(url: url) { return loaded }
            }
        }
        return nil
    }

    /// Reads a file down to mono samples with the silence stripped off both
    /// ends. That trim is not cosmetic: these recordings carry 60-100ms of
    /// silence before the transient, and left in, every pop would arrive that
    /// far behind its own haptic.
    private static func load(url: URL) -> (samples: [Float], rate: Double)? {
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let format = file.processingFormat
        let frames = AVAudioFrameCount(file.length)
        guard frames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              (try? file.read(into: buffer)) != nil,
              let channels = buffer.floatChannelData else { return nil }

        let count = Int(buffer.frameLength)
        guard count > 0 else { return nil }
        let channelCount = Int(format.channelCount)
        var mono = [Float](repeating: 0, count: count)
        for channel in 0..<channelCount {
            let data = channels[channel]
            for index in 0..<count { mono[index] += data[index] / Float(channelCount) }
        }
        return (trimmed(mono, rate: format.sampleRate), format.sampleRate)
    }

    /// Drops silence from both ends, keeping a couple of milliseconds of
    /// run-up so the attack itself is not clipped.
    private static func trimmed(_ samples: [Float], rate: Double,
                                threshold: Float = 0.02) -> [Float] {
        let peak = samples.reduce(Float(0)) { max($0, abs($1)) }
        guard peak > 0, let first = samples.firstIndex(where: { abs($0) > peak * threshold })
        else { return samples }
        var last = samples.count - 1
        while last > first, abs(samples[last]) <= peak * threshold { last -= 1 }
        let lead = Int(0.002 * rate)
        return Array(samples[max(0, first - lead)...last])
    }

    /// Linear-interpolated resample. Doubles as the sample-rate conversion and
    /// the pitch variation, since both are the same operation.
    private static func resample(_ samples: [Float], from rate: Double, pitch: Double) -> [Float] {
        let step = rate / sampleRate * pitch
        let count = max(1, Int(Double(samples.count) / step))
        var out = [Float](repeating: 0, count: count)
        for index in 0..<count {
            let position = Double(index) * step
            let whole = Int(position)
            let fraction = Float(position - Double(whole))
            let a = samples[min(whole, samples.count - 1)]
            let b = samples[min(whole + 1, samples.count - 1)]
            out[index] = a + (b - a) * fraction
        }
        return out
    }

    // MARK: - Shaping

    private static func buffer(_ samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(samples.count)) else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        for (index, sample) in samples.enumerated() {
            channel[index] = max(-1, min(1, sample))
        }
        return buffer
    }

    /// Two one-pole stages, so 12dB per octave above the corner. Applied to
    /// every voice: nothing in this app has any business being bright.
    private static func softened(_ samples: [Float], cutoff: Double) -> [Float] {
        let coefficient = Float(1 - exp(-2 * .pi * cutoff / sampleRate))
        var first: Float = 0
        var second: Float = 0
        return samples.map { sample in
            first += (sample - first) * coefficient
            second += (first - second) * coefficient
            return second
        }
    }

    /// Every voice normalised to the same headroom, so `Voice.gain` is the only
    /// thing deciding relative loudness and nothing reaches full scale.
    private static func normalized(_ samples: [Float], to peak: Float = 0.92) -> [Float] {
        let loudest = samples.reduce(Float(0)) { max($0, abs($1)) }
        guard loudest > 0.0001 else { return samples }
        let scale = peak / loudest
        return samples.map { $0 * scale }
    }

    // MARK: - Synthesis

    private static func render(_ voice: Voice, seed: UInt64) -> [Float] {
        var rng = SeededRNG(seed: seed &+ voice.seedOffset &* 7919)
        switch voice {
        // Calmed down: the noise is both quieter and darker, the ping is well
        // below the ear's sensitive band, and a 1.5ms ramp takes the click off
        // the front. It settles rather than snapping.
        case .detent:
            return click(&rng, duration: 0.055, ping: 780, spread: 90, decay: 0.0090,
                         noiseMix: 0.26, tilt: 0.22, attack: 0.0015)
        // Dry and neutral. A spinner tick is a small mechanical event, not a
        // note; the pitched part is only there to stop it being pure hiss.
        case .tick:
            return click(&rng, duration: 0.014, ping: 780, spread: 130,
                         decay: 0.0016, noiseMix: 0.72, tilt: 0.32)
        // Calmed the same way the dial was: the pitch dropped well clear of the
        // ear's sensitive band, most of the noise taken out and what is left
        // darkened, and a ramp on the front so it stops being a click. Kept
        // short because it fires up to forty times a second, where a run of
        // these should read as a soft rustle rather than a rasp.
        case .zip:
            return click(&rng, duration: 0.028, ping: 560, spread: 80, decay: 0.0040,
                         noiseMix: 0.32, tilt: 0.24, attack: 0.0012)
        case .clack: return switchClick(&rng)
        case .pop: return pop(&rng)
        case .crack: return crack(&rng)
        case .roll: return roll(&rng)
        case .swell: return swell(&rng)
        }
    }

    /// Noise transient plus a short pitched ping. `tilt` is the noise
    /// low-pass — lower is darker — and `noiseMix` how much of the result is
    /// noise rather than tone.
    private static func click(_ rng: inout SeededRNG, duration: Double, ping: Double,
                              spread: Double, decay: Double,
                              noiseMix: Float = 0.55, tilt: Float = 0.6,
                              attack: Double = 0) -> [Float] {
        let count = Int(duration * sampleRate)
        let frequency = ping + Double(rng.signedUnit()) * spread
        var samples = [Float](repeating: 0, count: count)
        var lowpass: Float = 0
        for index in 0..<count {
            let t = Double(index) / sampleRate
            lowpass += (Float(rng.signedUnit()) - lowpass) * tilt
            let body = Float(sin(2 * .pi * frequency * t)) * Float(exp(-t / decay))
            // Even a couple of milliseconds of ramp takes the edge off the
            // onset, which is most of what reads as "clicky".
            let rise = attack > 0 ? Float(1 - exp(-t / attack)) : 1
            samples[index] = (lowpass * noiseMix + body * (1 - noiseMix))
                * rise * Float(exp(-t / (decay * 2.2)))
        }
        return samples
    }

    /// A switch click: the snap of the mechanism going over centre, a short
    /// mid ring, and just enough body under it to have weight.
    /// Fitted to the reference recording rather than guessed.
    ///
    /// A wall switch is *three* transients, not one or two — the toggle going
    /// over centre, then the mechanism rattling to its stop — spaced 23 to 36ms
    /// apart. The energy sits in 3-8kHz with a ~700Hz component on the first
    /// hit only, and the decays run roughly 10ms, then 25, then 30.
    private static func switchClick(_ rng: inout SeededRNG) -> [Float] {
        let count = Int(0.17 * sampleRate)
        let gapA = 0.024 + Double(rng.unit()) * 0.012
        let gapB = gapA + 0.023 + Double(rng.unit()) * 0.012
        let low = 700 + Double(rng.signedUnit()) * 60
        let ring = 2950 + Double(rng.signedUnit()) * 320
        var samples = [Float](repeating: 0, count: count)
        var dark: Float = 0
        for index in 0..<count {
            let t = Double(index) / sampleRate
            // High-passed noise, not low-passed. The reference puts 29% of its
            // energy above 8kHz; a smoothed noise source cannot reach there,
            // and that is what left this sounding dull and bass-heavy.
            let raw = Float(rng.signedUnit())
            // A gentler high-pass than the fit wanted. Matching the reference's
            // top end exactly turned out to read as harsh rather than accurate.
            dark += (raw - dark) * 0.34
            let bright = raw - dark

            var value = bright * Float(exp(-t / 0.0034)) * 0.60
            // Balanced against the reference: it carries 39% of its energy
            // below 1kHz, so this body has to be present without dominating.
            value += Float(sin(2 * .pi * low * t)) * Float(exp(-t / 0.008)) * 0.24
            value += Float(sin(2 * .pi * ring * t)) * Float(exp(-t / 0.006)) * 0.20

            let second = t - gapA
            if second > 0 {
                value += bright * Float(exp(-second / 0.0060)) * 0.50
                value += Float(sin(2 * .pi * ring * second)) * Float(exp(-second / 0.012)) * 0.22
            }
            let third = t - gapB
            if third > 0 {
                value += bright * Float(exp(-third / 0.0070)) * 0.34
                value += Float(sin(2 * .pi * ring * 0.85 * third)) * Float(exp(-third / 0.014)) * 0.18
            }
            samples[index] = value
        }
        return samples
    }

    /// A real pop: the burst is the sound. The pitch sweep underneath is the
    /// cavity collapsing behind it, and it is what stops the burst being a
    /// bare click.
    /// Deliberately above the reference.
    ///
    /// The recording measures ~90% of its energy below 1kHz, and matching that
    /// faithfully came out dull and heavy. A bubble pop wants to be *cute*, and
    /// cute lives an octave up: the sweep lands near 430Hz instead of 200, it
    /// falls faster, it is shorter, and the balance is tipped towards tone
    /// rather than noise — noise is what made it thud.
    private static func pop(_ rng: inout SeededRNG) -> [Float] {
        let count = Int(0.038 * sampleRate)
        let start = 2200 + Double(rng.signedUnit()) * 420
        // The pitch it *lands* on is what you hear, not the one it starts from.
        // At 430 it still read as a low note; a small bubble sits near 800.
        let end = 790 + Double(rng.signedUnit()) * 130
        var samples = [Float](repeating: 0, count: count)
        var noise: Float = 0
        var phase: Double = 0
        for index in 0..<count {
            let t = Double(index) / sampleRate
            noise += (Float(rng.signedUnit()) - noise) * 0.82
            let burst = noise * Float(exp(-t / 0.0018)) * 0.55
            let frequency = end + (start - end) * exp(-t / 0.0060)
            phase += 2 * .pi * frequency / sampleRate
            let tone = Float(sin(phase)) * Float(exp(-t / 0.0080))
            samples[index] = burst + tone * 1.00
        }
        return samples
    }

    /// Left exactly as it was — a hard front, then debris. The secondary
    /// bursts are what stop it sounding like a single slap.
    private static func crack(_ rng: inout SeededRNG) -> [Float] {
        let count = Int(0.38 * sampleRate)
        var samples = [Float](repeating: 0, count: count)
        var highpass: Float = 0
        var previous: Float = 0
        for index in 0..<count {
            let t = Double(index) / sampleRate
            let noise = Float(rng.signedUnit())
            highpass = 0.85 * (highpass + noise - previous)
            previous = noise
            let front = highpass * Float(exp(-t / 0.045))
            let low = Float(sin(2 * .pi * 130 * t)) * Float(exp(-t / 0.030))
            samples[index] = front * 0.8 + low * 0.45
        }
        for step in 0..<5 {
            let at = Int((0.05 + Double(step) * 0.055) * sampleRate)
            let level = Float(0.5 * exp(-Double(step) * 0.45))
            let length = Int(0.03 * sampleRate)
            for offset in 0..<length where at + offset < count {
                let t = Double(offset) / sampleRate
                samples[at + offset] += Float(rng.signedUnit()) * Float(exp(-t / 0.006)) * level
            }
        }
        return samples
    }

    /// Soft and low. This fires several times a second, so it has to be
    /// something you stop noticing.
    private static func roll(_ rng: inout SeededRNG) -> [Float] {
        let count = Int(0.12 * sampleRate)
        let frequency = 118 + Double(rng.signedUnit()) * 12
        var samples = [Float](repeating: 0, count: count)
        for index in 0..<count {
            let t = Double(index) / sampleRate
            let rise = Float(1 - exp(-t / 0.008))
            samples[index] = Float(sin(2 * .pi * frequency * t)) * rise * Float(exp(-t / 0.038))
        }
        return samples
    }

    /// Breath, to match the arrival haptic — rises and falls, no attack.
    private static func swell(_ rng: inout SeededRNG) -> [Float] {
        let duration = 0.5
        let count = Int(duration * sampleRate)
        var samples = [Float](repeating: 0, count: count)
        var lowpass: Float = 0
        let frequency = 96 + Double(rng.signedUnit()) * 10
        for index in 0..<count {
            let t = Double(index) / sampleRate
            let progress = t / duration
            let shape = Float(sin(.pi * progress))
            lowpass += (Float(rng.signedUnit()) - lowpass) * 0.035
            let tone = Float(sin(2 * .pi * frequency * t))
            samples[index] = (lowpass * 2.2 + tone * 0.4) * shape * shape
        }
        return samples
    }
}

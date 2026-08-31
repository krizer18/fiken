import CoreHaptics
import Observation

/// Thin wrapper over Core Haptics. Every haptic number in the brief is written
/// in intensity/sharpness terms, which is exactly what CHHapticEvent takes —
/// no translation layer, no approximation.
@Observable
final class Haptics {
    /// Global scale from settings: 0.4 / 0.7 / 1.0.
    var strength: Float = 1.0

    private(set) var isSupported = false

    /// Sound layers *under* the haptics. Firing both from one call is what
    /// keeps them on the same instant — a separate call at the site would drift
    /// the moment anyone reordered a line.
    @ObservationIgnored var sound: SoundEngine?

    @ObservationIgnored private var engine: CHHapticEngine?

    init() {
        isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        guard isSupported else { return }
        start()
    }

    private func start() {
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.isAutoShutdownEnabled = true
            // The system stops the engine on backgrounding, audio-session
            // changes and media interruptions. Without these handlers it goes
            // quiet and reads as a bug in the fidget rather than in the engine.
            engine.stoppedHandler = { [weak self] _ in self?.engine = nil }
            engine.resetHandler = { [weak self] in try? self?.engine?.start() }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    /// Call when the scene becomes active again.
    func wake() {
        guard isSupported else { return }
        if engine == nil { start() } else { try? engine?.start() }
    }

    /// A weighted impact: a sharp transient for the click, layered over a short
    /// decaying continuous event for the body.
    ///
    /// A lone transient tops out at intensity 1.0 and still reads as thin. The
    /// continuous layer is what makes a switch feel like it has mass behind it,
    /// and it is the only way past that ceiling.
    func impact(intensity: Float, sharpness: Float, body: TimeInterval = 0.05,
                sound voice: SoundEngine.Voice? = nil) {
        if let voice { sound?.play(voice) }
        guard let engine else { return }
        let scaled = max(0, min(1, intensity * strength))
        let click = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: scaled),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: max(0, min(1, sharpness)))
        ], relativeTime: 0)
        let thud = CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: scaled),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
        ], relativeTime: 0, duration: body)
        let decay = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1),
            CHHapticParameterCurve.ControlPoint(relativeTime: body, value: 0)
        ], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [click, thud], parameterCurves: [decay])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            // Fall back to the plain tap rather than going silent. No voice —
            // it has already been played.
            transient(intensity: intensity, sharpness: sharpness)
        }
    }

    /// One long swell — a continuous event that rises and falls. Used for the
    /// bubble sheet's arrival signature.
    func swell(duration: TimeInterval = 0.6, peak: Float = 1.0, sharpness: Float = 0.3,
               sound voice: SoundEngine.Voice? = nil) {
        if let voice { sound?.play(voice) }
        guard let engine else { return }
        let scaled = max(0, min(1, peak * strength))
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: scaled),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        ], relativeTime: 0, duration: duration)
        let shape = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.05),
            CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.45, value: 1),
            CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0)
        ], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameterCurves: [shape])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            transient(intensity: peak, sharpness: sharpness)
        }
    }

    /// One heavy hit, then a run of taps decaying away behind it — the glass
    /// burst. Built as a single pattern so the decay timing is exact.
    func burst(peak: Float = 1.0, tail: Float = 0.15, sharpness: Float = 0.9,
               span: TimeInterval = 0.4, taps: Int = 6,
               sound voice: SoundEngine.Voice? = nil) {
        if let voice { sound?.play(voice) }
        guard let engine else { return }
        let scaledPeak = max(0, min(1, peak * strength))
        var events: [CHHapticEvent] = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: scaledPeak),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ], relativeTime: 0),
            // The body under the first hit — this is what makes it land hard.
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: scaledPeak),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0, duration: 0.07)
        ]
        for index in 1...max(1, taps) {
            let progress = Float(index) / Float(taps)
            let level = peak + (tail - peak) * progress
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity,
                                       value: max(0, min(1, level * strength))),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ], relativeTime: span * TimeInterval(progress)))
        }
        let decay = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1),
            CHHapticParameterCurve.ControlPoint(relativeTime: 0.07, value: 0)
        ], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: [decay])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            impact(intensity: peak, sharpness: sharpness)
        }
    }

    /// A run of evenly spaced taps, as one pattern so the spacing is exact.
    /// Used for arrival signatures — the dial's three quick taps, and so on.
    func taps(_ count: Int, spacing: TimeInterval, intensity: Float, sharpness: Float,
              sound voice: SoundEngine.Voice? = nil) {
        if let voice { sound?.play(voice) }
        guard let engine, count > 0 else { return }
        let scaled = max(0, min(1, intensity * strength))
        let events = (0..<count).map { index in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: scaled),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: max(0, min(1, sharpness)))
            ], relativeTime: TimeInterval(index) * spacing)
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            // Silence here is better than a partial signature.
        }
    }

    /// One sharp tap. Intensity is scaled by the global strength setting;
    /// sharpness is not, because sharpness is character, not volume.
    func transient(intensity: Float, sharpness: Float,
                   sound voice: SoundEngine.Voice? = nil) {
        if let voice { sound?.play(voice) }
        guard let engine else { return }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity,
                                       value: max(0, min(1, intensity * strength))),
                CHHapticEventParameter(parameterID: .hapticSharpness,
                                       value: max(0, min(1, sharpness)))
            ],
            relativeTime: 0
        )
        do {
            let player = try engine.makePlayer(with: CHHapticPattern(events: [event], parameters: []))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // A dropped tick is better than a crash mid-fidget.
        }
    }
}

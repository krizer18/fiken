import CoreGraphics

/// Deterministic, fast PRNG. One seed reproduces an entire drawn frame, which is
/// what lets the boil advance in discrete steps instead of every element
/// jittering independently.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Scramble first: the boil clock hands out small sequential seeds, and
        // xorshift on those alone produces visibly correlated streams.
        var s = seed &* 6364136223846793005 &+ 1442695040888963407
        s ^= s >> 33
        s = s &* 0xff51afd7ed558ccd
        s ^= s >> 33
        state = s == 0 ? 0x9E3779B97F4A7C15 : s
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    /// Uniform in 0...1.
    mutating func unit() -> CGFloat {
        CGFloat(Double(next() >> 11) * (1.0 / 9007199254740992.0))
    }

    /// Uniform in -1...1.
    mutating func signedUnit() -> CGFloat {
        unit() * 2 - 1
    }
}

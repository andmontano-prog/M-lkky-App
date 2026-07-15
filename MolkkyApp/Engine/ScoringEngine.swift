import Foundation

/// House rules for a single game. Defaults are standard Mölkky; every value is
/// adjustable from the in-game rules sheet.
struct RuleConfig: Codable, Equatable {
    var scoreToWin: Int = 50
    var overshootReset: Int = 25
    var strikesToEliminate: Int = 3
    var firstTimerExtraStrikes: Int = 1

    static let standard = RuleConfig()
}

/// Derived state for one player, computed purely from their ordered throws.
struct PlayerScoreState: Equatable {
    var score: Int = 0
    /// Trailing run of consecutive misses (zeros).
    var missStreak: Int = 0
    var isEliminated: Bool = false
    var hasReachedTarget: Bool = false
    /// Indices into the throw list where an overshoot reset happened — used to
    /// annotate the history strip.
    var resetThrowIndices: [Int] = []
}

/// Pure, deterministic Mölkky scoring. No SwiftUI, no SwiftData — trivially
/// unit-testable (see Tests/ScoringEngineTests.swift). A single throw is always
/// worth 0–12 (one pin = its number, multiple pins = the count), so the engine
/// takes the already-resolved 0–12 value per throw.
enum ScoringEngine {

    static func maxStrikes(rules: RuleConfig, isFirstTimer: Bool) -> Int {
        rules.strikesToEliminate + (isFirstTimer ? rules.firstTimerExtraStrikes : 0)
    }

    /// Reduce a player's throw list into their current derived state.
    static func derive(throws throwValues: [Int],
                       rules: RuleConfig,
                       isFirstTimer: Bool) -> PlayerScoreState {
        var state = PlayerScoreState()
        let allowed = maxStrikes(rules: rules, isFirstTimer: isFirstTimer)

        for (index, value) in throwValues.enumerated() {
            if value == 0 {
                state.missStreak += 1
                if state.missStreak >= allowed {
                    state.isEliminated = true
                }
            } else {
                state.missStreak = 0
                let next = state.score + value
                if next > rules.scoreToWin {
                    state.score = rules.overshootReset
                    state.resetThrowIndices.append(index)
                } else {
                    state.score = next
                }
                if state.score == rules.scoreToWin {
                    state.hasReachedTarget = true
                }
            }
        }
        return state
    }

    /// Whether a throw value is legal for a single Mölkky throw.
    static func isValidThrow(_ value: Int) -> Bool { (0...12).contains(value) }
}

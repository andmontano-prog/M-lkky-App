import Foundation
import SwiftData

/// A single game — its roster, live turn state, house rules, and outcome.
/// Persisted locally (SwiftData); an in-progress game is what powers
/// session-resume on next launch.
@Model
final class Game {
    var createdAt: Date
    var completedAt: Date?
    var isComplete: Bool
    var winnerName: String?

    // Live turn state (kept on the model so a backgrounded game resumes exactly).
    var currentTurnIndex: Int
    var round: Int

    // House rules, stored flat and surfaced as a RuleConfig.
    var ruleScoreToWin: Int
    var ruleOvershootReset: Int
    var ruleStrikesToEliminate: Int
    var ruleFirstTimerExtraStrikes: Int

    @Relationship(deleteRule: .cascade, inverse: \GameParticipant.game)
    var participants: [GameParticipant]

    init(rules: RuleConfig = .standard, createdAt: Date = .now) {
        self.createdAt = createdAt
        self.completedAt = nil
        self.isComplete = false
        self.winnerName = nil
        self.currentTurnIndex = 0
        self.round = 1
        self.ruleScoreToWin = rules.scoreToWin
        self.ruleOvershootReset = rules.overshootReset
        self.ruleStrikesToEliminate = rules.strikesToEliminate
        self.ruleFirstTimerExtraStrikes = rules.firstTimerExtraStrikes
        self.participants = []
    }

    var rules: RuleConfig {
        get {
            RuleConfig(scoreToWin: ruleScoreToWin,
                       overshootReset: ruleOvershootReset,
                       strikesToEliminate: ruleStrikesToEliminate,
                       firstTimerExtraStrikes: ruleFirstTimerExtraStrikes)
        }
        set {
            ruleScoreToWin = newValue.scoreToWin
            ruleOvershootReset = newValue.overshootReset
            ruleStrikesToEliminate = newValue.strikesToEliminate
            ruleFirstTimerExtraStrikes = newValue.firstTimerExtraStrikes
        }
    }

    /// Participants in throw order.
    var orderedParticipants: [GameParticipant] {
        participants.sorted { $0.order < $1.order }
    }

    /// Participants still in the game (not eliminated).
    var activeParticipants: [GameParticipant] {
        orderedParticipants.filter { !$0.state(rules: rules).isEliminated }
    }

    var currentParticipant: GameParticipant? {
        let ordered = orderedParticipants
        guard ordered.indices.contains(currentTurnIndex) else { return ordered.first }
        return ordered[currentTurnIndex]
    }
}

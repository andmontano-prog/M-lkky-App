import Foundation
import SwiftData
import SwiftUI

/// Drives a live game: records throws, advances turns, applies the rules
/// (overshoot reset, strike elimination, exact-win), and supports undo + editing
/// past throws. All persistence flows through SwiftData so a backgrounded game
/// resumes exactly where it left off.
@Observable
final class GameController {
    let game: Game
    private let context: ModelContext

    /// Set the moment the game ends — drives the win celebration.
    var winner: GameParticipant?
    var winReason: String = ""

    init(game: Game, context: ModelContext) {
        self.game = game
        self.context = context
    }

    var rules: RuleConfig { game.rules }
    var current: GameParticipant? { game.currentParticipant }

    // MARK: - Recording

    func recordThrow(_ value: Int) {
        guard !game.isComplete, let player = current else { return }
        var throwsCopy = player.throwValues
        throwsCopy.append(value)
        player.throwValues = throwsCopy

        let state = player.state(rules: rules)
        if state.hasReachedTarget {
            finish(winner: player, reason: "reached \(rules.scoreToWin)")
            save()
            return
        }
        advanceTurn()
        save()
    }

    func undoLastThrow() {
        guard let player = current, !player.throwValues.isEmpty else { return }
        var throwsCopy = player.throwValues
        throwsCopy.removeLast()
        player.throwValues = throwsCopy
        save()
    }

    /// Edit any past throw for a participant and recompute downstream state.
    func editThrow(for participant: GameParticipant, at index: Int, to value: Int) {
        guard participant.throwValues.indices.contains(index),
              ScoringEngine.isValidThrow(value) else { return }
        var throwsCopy = participant.throwValues
        throwsCopy[index] = value
        participant.throwValues = throwsCopy

        // Re-evaluate the whole game outcome after an edit.
        reevaluateOutcome()
        save()
    }

    func setFirstTimer(_ participant: GameParticipant, _ isFirstTimer: Bool) {
        participant.isFirstTimer = isFirstTimer
        reevaluateOutcome()
        save()
    }

    // MARK: - Turn flow

    private func advanceTurn() {
        let ordered = game.orderedParticipants
        guard ordered.count > 1 else {
            // Solo game: reaching target is the only end condition, handled above.
            return
        }
        let active = game.activeParticipants
        if active.count <= 1 {
            finish(winner: active.first, reason: "last one standing")
            return
        }
        var guardCount = 0
        repeat {
            game.currentTurnIndex = (game.currentTurnIndex + 1) % ordered.count
            if game.currentTurnIndex == 0 { game.round += 1 }
            guardCount += 1
        } while ordered[game.currentTurnIndex].state(rules: rules).isEliminated && guardCount < ordered.count * 2
    }

    private func reevaluateOutcome() {
        // Recheck win / last-standing after an edit.
        let ordered = game.orderedParticipants
        if let champ = ordered.first(where: { $0.state(rules: rules).hasReachedTarget }) {
            finish(winner: champ, reason: "reached \(rules.scoreToWin)")
            return
        }
        let active = game.activeParticipants
        if ordered.count > 1, active.count <= 1 {
            finish(winner: active.first, reason: "last one standing")
            return
        }
        // Otherwise the game is (still) in progress.
        game.isComplete = false
        game.completedAt = nil
        game.winnerName = nil
        winner = nil
    }

    private func finish(winner participant: GameParticipant?, reason: String) {
        game.isComplete = true
        game.completedAt = .now
        game.winnerName = participant?.name
        self.winner = participant
        self.winReason = reason
    }

    // MARK: - Persistence

    private func save() {
        try? context.save()
    }
}

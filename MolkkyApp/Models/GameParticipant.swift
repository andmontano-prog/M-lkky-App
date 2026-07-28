import Foundation
import SwiftData

/// One player's seat in a game: their name snapshot, throw order, first-timer
/// flag, and the ordered list of throw values (each 0–12).
@Model
final class GameParticipant {
    var name: String
    var order: Int
    var isFirstTimer: Bool
    var throwValues: [Int]
    var game: Game?

    init(name: String, order: Int, isFirstTimer: Bool = false, throwValues: [Int] = []) {
        self.name = name
        self.order = order
        self.isFirstTimer = isFirstTimer
        self.throwValues = throwValues
    }

    /// Derived score state for this participant under the given rules.
    func state(rules: RuleConfig) -> PlayerScoreState {
        ScoringEngine.derive(throws: throwValues, rules: rules, isFirstTimer: isFirstTimer)
    }
}

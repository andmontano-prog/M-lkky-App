import XCTest
@testable import MolkkyApp

/// Unit tests for the pure Mölkky scoring engine. These mirror the scenarios
/// validated during development (see PR notes). To run them, add a Unit Testing
/// Bundle target to the Xcode project and include this file — the engine is
/// dependency-free so no host app is required.
final class ScoringEngineTests: XCTestCase {

    private let standard = RuleConfig.standard

    func testNormalAccumulation() {
        let s = ScoringEngine.derive(throws: [12, 10, 9], rules: standard, isFirstTimer: false)
        XCTAssertEqual(s.score, 31)
        XCTAssertFalse(s.isEliminated)
        XCTAssertFalse(s.hasReachedTarget)
    }

    func testOvershootResetsTo25() {
        // 12+12+12+12 = 48, then +9 = 57 > 50 -> reset to 25
        let s = ScoringEngine.derive(throws: [12, 12, 12, 12, 9], rules: standard, isFirstTimer: false)
        XCTAssertEqual(s.score, 25)
        XCTAssertEqual(s.resetThrowIndices, [4])
        XCTAssertFalse(s.hasReachedTarget)
    }

    func testExactWin() {
        let s = ScoringEngine.derive(throws: [12, 12, 12, 12, 2], rules: standard, isFirstTimer: false)
        XCTAssertEqual(s.score, 50)
        XCTAssertTrue(s.hasReachedTarget)
    }

    func testThreeMissesEliminates() {
        let s = ScoringEngine.derive(throws: [0, 0, 0], rules: standard, isFirstTimer: false)
        XCTAssertTrue(s.isEliminated)
        XCTAssertEqual(s.missStreak, 3)
    }

    func testTwoMissesSurvives() {
        let s = ScoringEngine.derive(throws: [0, 0], rules: standard, isFirstTimer: false)
        XCTAssertFalse(s.isEliminated)
    }

    func testMissStreakResetsOnHit() {
        let s = ScoringEngine.derive(throws: [0, 0, 5, 0, 0, 0], rules: standard, isFirstTimer: false)
        XCTAssertEqual(s.score, 5)
        XCTAssertTrue(s.isEliminated)
        XCTAssertEqual(s.missStreak, 3)
    }

    func testFirstTimerGetsExtraStrike() {
        let survives = ScoringEngine.derive(throws: [0, 0, 0], rules: standard, isFirstTimer: true)
        XCTAssertFalse(survives.isEliminated, "First-timer should survive 3 misses with +1 strike")

        let out = ScoringEngine.derive(throws: [0, 0, 0, 0], rules: standard, isFirstTimer: true)
        XCTAssertTrue(out.isEliminated)
    }

    func testCustomRules() {
        let rules = RuleConfig(scoreToWin: 30, overshootReset: 15, strikesToEliminate: 2, firstTimerExtraStrikes: 1)
        let win = ScoringEngine.derive(throws: [12, 12, 6], rules: rules, isFirstTimer: false)
        XCTAssertEqual(win.score, 30)
        XCTAssertTrue(win.hasReachedTarget)

        let out = ScoringEngine.derive(throws: [0, 0], rules: rules, isFirstTimer: false)
        XCTAssertTrue(out.isEliminated)
    }
}

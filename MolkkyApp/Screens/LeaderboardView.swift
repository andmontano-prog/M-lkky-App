import SwiftUI
import SwiftData

/// Career standings across every completed game, one row per roster player.
/// Ranked by the sharpest win (fewest rounds to close out a game), then by
/// total wins — so both a single brilliant game and a long record of them
/// climb the board.
struct LeaderboardView: View {
    @Query private var players: [Player]
    @Query private var allGames: [Game]

    private var rows: [LeaderboardStat] {
        LeaderboardStat.build(players: players, games: allGames)
    }

    private var ranked: [LeaderboardStat] {
        rows.filter { $0.gamesPlayed > 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ScreenTitle(title: "Leaderboard",
                                subtitle: "Fewest rounds to win, then most wins")

                    if ranked.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(ranked.enumerated()), id: \.element.id) { index, stat in
                            LeaderboardRow(rank: index + 1, stat: stat)
                        }
                        footnote
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
                .screenEntrance()
            }
            .background(MolkkyBackground())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No standings yet.")
                .font(.suseExtraBold(16)).foregroundStyle(Palette.cream)
            Text("Capture a roster and finish a game — your players climb the board from there.")
                .font(.suseExtraLight(14)).foregroundStyle(Palette.sage)
        }
        .padding(.vertical, 8)
    }

    private var footnote: some View {
        Text("Best = fewest rounds to close out a win · Avg = mean rounds per win · Strikes = total misses.")
            .font(.suseExtraLight(11.5)).foregroundStyle(Palette.sage)
            .padding(.top, 6).padding(.horizontal, 4)
    }
}

/// One standings row: rank marker, player, and the three headline stats.
struct LeaderboardRow: View {
    let rank: Int
    let stat: LeaderboardStat

    private var medal: String? {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return nil
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    if let medal {
                        Text(medal).font(.system(size: 22))
                    } else {
                        Text("\(rank)")
                            .font(.suseExtraBold(15)).foregroundStyle(Palette.inkSoft)
                    }
                }
                .frame(width: 26)

                InitialsBadge(name: stat.name, highlighted: rank == 1, size: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.name)
                        .font(.suseExtraBold(16)).foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    Text("\(stat.gamesPlayed) games played")
                        .font(.suseExtraLight(12)).foregroundStyle(Palette.inkSoft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                headline(stat.bestLabel, "Best", tint: Palette.forest)
                headline("\(stat.wins)", "Wins", tint: Palette.ink)
            }

            Rectangle()
                .fill(Palette.inkSoft.opacity(0.12))
                .frame(height: 1)

            HStack(spacing: 0) {
                StatCell(value: stat.avgLabel, label: "Avg rds")
                StatCell(value: stat.accuracyLabel, label: "Hits")
                StatCell(value: "\(stat.totalStrikes)", label: "Strikes")
                StatCell(value: stat.winRateLabel, label: "Win%")
            }
        }
        .padding(.vertical, 12).padding(.horizontal, 14)
        .background(Palette.cream, in: RoundedRectangle(cornerRadius: 15))
    }

    private func headline(_ value: String, _ label: String, tint: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.suseExtraBold(19)).monospacedDigit().foregroundStyle(tint)
            Text(label)
                .font(.suseSemiBold(9)).textCase(.uppercase).tracking(0.8)
                .foregroundStyle(Palette.inkSoft)
        }
        .frame(minWidth: 40)
    }
}

/// A single mini-stat in the row's secondary strip.
private struct StatCell: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.suseExtraBold(14)).monospacedDigit().foregroundStyle(Palette.ink)
            Text(label)
                .font(.suseSemiBold(9)).textCase(.uppercase).tracking(0.6)
                .foregroundStyle(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Career totals for one roster player, aggregated from completed games.
struct LeaderboardStat: Identifiable {
    let id: String
    let name: String
    let wins: Int
    let gamesPlayed: Int
    /// Fewest rounds it took this player to close out a win (nil if never won).
    let bestRoundsToWin: Int?
    /// Average rounds-to-win across their victories.
    let avgRoundsToWin: Double?
    /// Share of throws that knocked down at least one pin, across all games.
    let accuracy: Double
    /// Total missed throws (zeros) across all games — Mölkky "strikes".
    let totalStrikes: Int
    let lastPlayed: Date?

    var winRate: Double { gamesPlayed == 0 ? 0 : Double(wins) / Double(gamesPlayed) }

    var bestLabel: String { bestRoundsToWin.map(String.init) ?? "—" }
    var avgLabel: String { avgRoundsToWin.map { String(format: "%.1f", $0) } ?? "—" }
    var winRateLabel: String { gamesPlayed == 0 ? "—" : "\(Int((winRate * 100).rounded()))%" }
    var accuracyLabel: String { "\(Int((accuracy * 100).rounded()))%" }

    /// Aggregate every roster player against the completed games, then rank:
    /// fewest rounds-to-win first (winless players sink to the bottom), tie-broken
    /// by wins, then win rate, then name.
    static func build(players: [Player], games: [Game]) -> [LeaderboardStat] {
        let completed = games.filter { $0.isComplete }
        let stats = players.map { player -> LeaderboardStat in
            let name = player.name
            var wins = 0, played = 0, hits = 0, throwCount = 0, strikes = 0
            var roundsWon: [Int] = []

            for game in completed {
                guard let seat = game.participants.first(where: { $0.name == name }) else { continue }
                played += 1
                throwCount += seat.throwValues.count
                hits += seat.throwValues.filter { $0 > 0 }.count
                strikes += seat.throwValues.filter { $0 == 0 }.count
                if game.winnerName == name {
                    wins += 1
                    roundsWon.append(game.round)
                }
            }

            let best = roundsWon.min()
            let avg = roundsWon.isEmpty ? nil
                : Double(roundsWon.reduce(0, +)) / Double(roundsWon.count)
            let accuracy = throwCount == 0 ? 0 : Double(hits) / Double(throwCount)

            return LeaderboardStat(id: name, name: name, wins: wins,
                                   gamesPlayed: played, bestRoundsToWin: best,
                                   avgRoundsToWin: avg, accuracy: accuracy,
                                   totalStrikes: strikes, lastPlayed: player.lastPlayedAt)
        }

        return stats.sorted(by: rank)
    }

    /// Ordering per spec: least rounds to win → most wins → best win rate → name.
    private static func rank(_ a: LeaderboardStat, _ b: LeaderboardStat) -> Bool {
        switch (a.bestRoundsToWin, b.bestRoundsToWin) {
        case let (x?, y?) where x != y: return x < y
        case (.some, nil): return true          // a has a win, b doesn't → a first
        case (nil, .some): return false
        default: break                          // both nil or equal → fall through
        }
        if a.wins != b.wins { return a.wins > b.wins }
        if a.winRate != b.winRate { return a.winRate > b.winRate }
        return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
    }
}

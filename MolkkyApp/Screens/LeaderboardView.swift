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
                        columnHeader
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

    private var columnHeader: some View {
        HStack(spacing: 0) {
            Text("Player")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Best")
                .frame(width: 52, alignment: .trailing)
            Text("Wins")
                .frame(width: 46, alignment: .trailing)
            Text("Win%")
                .frame(width: 52, alignment: .trailing)
        }
        .font(.suseSemiBold(10)).textCase(.uppercase).tracking(1)
        .foregroundStyle(Palette.sage)
        .padding(.horizontal, 14)
        .padding(.top, 4)
    }

    private var footnote: some View {
        Text("Best = fewest rounds to close out a win.")
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
                Text("\(stat.gamesPlayed) games · \(stat.accuracyLabel) hits")
                    .font(.suseExtraLight(12)).foregroundStyle(Palette.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(stat.bestLabel)
                .font(.suseExtraBold(17)).monospacedDigit()
                .foregroundStyle(Palette.forest)
                .frame(width: 40, alignment: .trailing)
            Text("\(stat.wins)")
                .font(.suseExtraBold(17)).monospacedDigit()
                .foregroundStyle(Palette.ink)
                .frame(width: 40, alignment: .trailing)
            Text(stat.winRateLabel)
                .font(.suseSemiBold(13)).monospacedDigit()
                .foregroundStyle(Palette.inkSoft)
                .frame(width: 46, alignment: .trailing)
        }
        .padding(.vertical, 11).padding(.horizontal, 14)
        .background(Palette.cream, in: RoundedRectangle(cornerRadius: 15))
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
    let lastPlayed: Date?

    var winRate: Double { gamesPlayed == 0 ? 0 : Double(wins) / Double(gamesPlayed) }

    var bestLabel: String { bestRoundsToWin.map(String.init) ?? "—" }
    var winRateLabel: String { gamesPlayed == 0 ? "—" : "\(Int((winRate * 100).rounded()))%" }
    var accuracyLabel: String { "\(Int((accuracy * 100).rounded()))%" }

    /// Aggregate every roster player against the completed games, then rank:
    /// fewest rounds-to-win first (winless players sink to the bottom), tie-broken
    /// by wins, then win rate, then name.
    static func build(players: [Player], games: [Game]) -> [LeaderboardStat] {
        let completed = games.filter { $0.isComplete }
        let stats = players.map { player -> LeaderboardStat in
            let name = player.name
            var wins = 0, played = 0, hits = 0, throwCount = 0
            var roundsWon: [Int] = []

            for game in completed {
                guard let seat = game.participants.first(where: { $0.name == name }) else { continue }
                played += 1
                throwCount += seat.throwValues.count
                hits += seat.throwValues.filter { $0 > 0 }.count
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
                                   lastPlayed: player.lastPlayedAt)
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

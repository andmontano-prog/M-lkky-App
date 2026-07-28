import SwiftUI
import SwiftData

struct GamesListView: View {
    @Query private var allGames: [Game]
    @State private var path: [GameFlow] = []
    @State private var newestFirst = true

    private var games: [Game] {
        allGames.filter { $0.isComplete }
            .sorted { newestFirst ? $0.createdAt > $1.createdAt : $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ScreenTitle(title: "Games")

                    HStack {
                        Text("\(games.count) games played")
                            .font(.suseExtraBold(15)).foregroundStyle(Palette.cream)
                        Spacer()
                        Button {
                            newestFirst.toggle()
                        } label: {
                            Label(newestFirst ? "Newest" : "Oldest", systemImage: "arrow.up.arrow.down")
                                .font(.suseSemiBold(12.5)).foregroundStyle(Palette.lime)
                        }
                    }
                    .padding(.top, 4)

                    if games.isEmpty {
                        Text("Play your first game and it'll show up here.")
                            .font(.suseExtraLight(14)).foregroundStyle(Palette.sage)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(games) { game in
                            GameHistoryRow(game: game) {
                                let names = game.orderedParticipants.map { $0.name }
                                path.append(.setup(seedNames: names))
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
                .screenEntrance()
            }
            .background(MolkkyBackground())
            .navigationBarTitleDisplayMode(.inline)
            .gameFlowDestinations(path: $path)
        }
    }
}

struct GameHistoryRow: View {
    let game: Game
    let onReuse: () -> Void

    var body: some View {
        Button(action: onReuse) {
            HStack(spacing: 14) {
                VStack(spacing: 0) {
                    Text(game.createdAt.formatted(.dateTime.day()))
                        .font(.suseExtraBold(22)).foregroundStyle(Palette.forest)
                    Text(game.createdAt.formatted(.dateTime.month(.abbreviated)))
                        .font(.suseSemiBold(10)).textCase(.uppercase).tracking(1)
                        .foregroundStyle(Palette.inkSoft)
                }
                .frame(width: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(game.winnerName ?? "—") won")
                        .font(.suseExtraBold(16)).foregroundStyle(Palette.ink)
                    Text("\(game.participants.count) players · to \(game.ruleScoreToWin)")
                        .font(.suseExtraLight(12.5)).foregroundStyle(Palette.inkSoft)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(game.ruleScoreToWin)").font(.suseExtraBold(20))
                        .foregroundStyle(Palette.forest).monospacedDigit()
                    Text("Winner").font(.suseSemiBold(10)).textCase(.uppercase).tracking(0.8)
                        .foregroundStyle(Palette.inkSoft)
                }
            }
            .padding(14)
            .background(Palette.cream, in: RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
    }
}

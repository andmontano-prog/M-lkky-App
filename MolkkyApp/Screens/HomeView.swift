import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Game.createdAt, order: .reverse) private var games: [Game]
    @Query(sort: \Player.name) private var players: [Player]

    @State private var path: [GameFlow] = []
    @State private var resumeGame: Game?
    @State private var resumeChecked = false

    private var completedGames: [Game] { games.filter { $0.isComplete } }
    private var recent: [Game] { Array(completedGames.prefix(2)) }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ScreenTitle(title: "Home", subtitle: "Ready when you are.")
                        .padding(.bottom, 4)

                    startCard
                    managePlayersTile

                    HStack {
                        Text("Recent games").font(.suseExtraBold(15)).foregroundStyle(Palette.cream)
                        Spacer()
                    }
                    .padding(.top, 12)

                    if recent.isEmpty {
                        Text("No games yet — your first win goes here.")
                            .font(.suseExtraLight(14))
                            .foregroundStyle(Palette.sage)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(recent) { game in
                            RecentGameRow(game: game)
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
            .sheet(item: $resumeGame) { game in
                ResumePromptView(
                    game: game,
                    onContinue: {
                        let id = game.persistentModelID
                        resumeGame = nil
                        path = [.scoring(id)]
                    },
                    onStartOver: {
                        context.delete(game)
                        try? context.save()
                        resumeGame = nil
                    }
                )
                .presentationDetents([.height(340)])
            }
            .onAppear(perform: checkForResume)
        }
    }

    private var startCard: some View {
        Button {
            path.append(.setup(seedNames: []))
        } label: {
            ZStack(alignment: .topTrailing) {
                SkittleCluster().opacity(0.18).offset(x: 6, y: -6)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start\nnew game")
                        .font(.molkkyHeader(44))
                        .foregroundStyle(Palette.forest)
                    Text("Build a roster in seconds")
                        .font(.suseSemiBold(13))
                        .foregroundStyle(Palette.forest.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
            }
            .background(Palette.lime, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var managePlayersTile: some View {
        NavigationLink(value: GameFlow.setup(seedNames: [])) {
            HStack(spacing: 14) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(Palette.lime)
                    .frame(width: 42, height: 42)
                    .background(Palette.lime.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Manage players").font(.suseExtraBold(16)).foregroundStyle(Palette.cream)
                    Text("\(players.count) on the bench").font(.suseExtraLight(12.5)).foregroundStyle(Palette.sage)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Palette.sage)
            }
            .padding(16)
            .background(Palette.cream.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.cream.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func checkForResume() {
        guard !resumeChecked else { return }
        resumeChecked = true
        resumeGame = games.first { !$0.isComplete && !$0.participants.isEmpty }
    }
}

struct RecentGameRow: View {
    let game: Game
    private var winner: String { game.winnerName ?? "—" }
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "trophy.fill")
                .foregroundStyle(Palette.lime)
                .frame(width: 44, height: 44)
                .background(Palette.forest, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(winner) won").font(.suseExtraBold(16)).foregroundStyle(Palette.ink)
                Text("\(game.createdAt.formatted(.dateTime.month().day())) · \(game.participants.count) players")
                    .font(.suseExtraLight(12.5)).foregroundStyle(Palette.inkSoft)
            }
            Spacer()
            Text("\(game.ruleScoreToWin)")
                .font(.suseExtraBold(22)).foregroundStyle(Palette.forest)
                .monospacedDigit()
        }
        .padding(14)
        .background(Palette.cream, in: RoundedRectangle(cornerRadius: 13))
    }
}

/// Decorative row of skittles for the start card.
struct SkittleCluster: View {
    var body: some View {
        HStack(spacing: -2) {
            ForEach(0..<3, id: \.self) { _ in
                Image(systemName: "cone.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Palette.forest)
            }
        }
    }
}

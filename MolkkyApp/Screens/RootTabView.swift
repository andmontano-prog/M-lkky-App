import SwiftUI
import SwiftData

/// A step in the new-game flow, pushed onto a NavigationStack path.
enum GameFlow: Hashable {
    case setup(seedNames: [String])
    case scoring(PersistentIdentifier)
}

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            GamesListView()
                .tabItem { Label("Games", systemImage: "square.grid.2x2.fill") }
            LeaderboardView()
                .tabItem { Label("Leaderboard", systemImage: "trophy.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

extension View {
    /// Shared setup → scoring destinations for any NavigationStack that drives
    /// the game flow (Home and Games both use it).
    func gameFlowDestinations(path: Binding<[GameFlow]>) -> some View {
        navigationDestination(for: GameFlow.self) { step in
            switch step {
            case .setup(let seed):
                NewGameSetupView(seedNames: seed, path: path)
            case .scoring(let id):
                ScoringLoader(gameID: id, path: path)
            }
        }
    }
}

/// Resolves a persistent id back into a live Game for the scoring screen.
struct ScoringLoader: View {
    @Environment(\.modelContext) private var context
    let gameID: PersistentIdentifier
    @Binding var path: [GameFlow]

    var body: some View {
        if let game = context.model(for: gameID) as? Game {
            ScoringView(game: game, path: $path)
        } else {
            ContentUnavailableView("Game not found", systemImage: "exclamationmark.triangle")
        }
    }
}

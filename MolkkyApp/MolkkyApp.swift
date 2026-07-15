import SwiftUI
import SwiftData

@main
struct MolkkyAppMain: App {
    let modelContainer: ModelContainer = {
        let schema = Schema([Player.self, Game.self, GameParticipant.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(Palette.lime)
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}

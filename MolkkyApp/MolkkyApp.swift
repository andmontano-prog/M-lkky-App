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

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                Palette.forest.ignoresSafeArea()   // forest floor — no white flash in the launch→SwiftUI gap

                RootTabView()
                    .tint(Palette.lime)
                    .preferredColorScheme(.dark)

                if showSplash {
                    SplashView(onFinish: {
                        withAnimation(.easeOut(duration: 0.35)) { showSplash = false }
                    })
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
        .modelContainer(modelContainer)
    }
}

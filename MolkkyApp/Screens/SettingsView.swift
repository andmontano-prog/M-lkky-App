import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Game.createdAt) private var games: [Game]
    @Query private var players: [Player]
    @State private var confirmDelete = false

    private var playingSince: String {
        guard let first = games.first?.createdAt else { return "just getting started" }
        let months = Calendar.current.dateComponents([.month], from: first, to: .now).month ?? 0
        if months < 1 { return "less than a month" }
        let years = months / 12
        let rem = months % 12
        if years == 0 { return "\(months) month\(months == 1 ? "" : "s")" }
        return "\(years)yr\(rem > 0 ? " \(rem)mo" : "")"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ScreenTitle(title: "Settings", subtitle: "All on this phone. No account, ever.")

                    VStack(spacing: 4) {
                        Text(playingSince)
                            .font(.molkkyHeader(56)).foregroundStyle(Palette.lime)
                            .momoScriptReveal()
                        Text("playing with this app")
                            .font(.suseExtraLight(13)).foregroundStyle(Palette.sage)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(Palette.pine, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.lime.opacity(0.14), lineWidth: 1))
                    .padding(.bottom, 6)

                    NavigationLink { RulesView() } label: {
                        settingRow(icon: "book.fill", title: "How to play Mölkky", value: "Illustrated rules")
                    }
                    .buttonStyle(.plain)

                    Button { confirmDelete = true } label: {
                        settingRow(icon: "trash.fill", title: "Delete all data",
                                   value: "\(games.count) games · \(players.count) players", danger: true)
                    }
                    .buttonStyle(.plain)
                    .alert("Delete everything?", isPresented: $confirmDelete) {
                        Button("Delete", role: .destructive) { deleteAll() }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This wipes every game and player on this device. It can't be undone.")
                    }

                    Text("Made for the backyard. Works fully offline.")
                        .font(.suseExtraLight(12)).foregroundStyle(Palette.sage)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
                .screenEntrance()
            }
            .background(MolkkyBackground())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func settingRow(icon: String, title: String, value: String, danger: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(danger ? Palette.danger : Palette.lime)
                .frame(width: 40, height: 40)
                .background((danger ? Palette.danger : Palette.lime).opacity(0.16), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.suseExtraBold(15)).foregroundStyle(Palette.cream)
                Text(value).font(.suseExtraLight(12.5)).foregroundStyle(Palette.sage)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Palette.sage)
        }
        .padding(16)
        .background(Palette.cream.opacity(0.06), in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Palette.cream.opacity(0.12), lineWidth: 1))
    }

    private func deleteAll() {
        for game in games { context.delete(game) }
        for player in players { context.delete(player) }
        try? context.save()
    }
}

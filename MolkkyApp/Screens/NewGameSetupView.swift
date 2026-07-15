import SwiftUI
import SwiftData

private struct RosterEntry: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var lastPlayedAt: Date?
    var isFirstTimer: Bool = false
}

struct NewGameSetupView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Player.name) private var players: [Player]

    let seedNames: [String]
    @Binding var path: [GameFlow]

    @State private var roster: [RosterEntry] = []
    @State private var draft: String = ""
    @State private var showWarningNote = false

    private let largeGameThreshold = 10

    var body: some View {
        VStack(spacing: 0) {
            actionBar
            ScreenTitle(title: "New game")
                .padding(.horizontal, 22)
                .padding(.bottom, 8)

            addRow
            suggestions
            rosterList

            footer
        }
        .screenEntrance()
        .background(MolkkyBackground())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { if roster.isEmpty { roster = seedNames.map { entry(for: $0) } } }
    }

    // MARK: Action bar

    private var actionBar: some View {
        HStack(spacing: 6) {
            barButton("chevron.left") { dismiss() }
            barButton("arrow.counterclockwise") { roster.removeAll() }
            barButton("shuffle") { roster.shuffle() }
            Menu {
                Button("Name · A–Z") { roster.sort { $0.name < $1.name } }
                Button("Name · Z–A") { roster.sort { $0.name > $1.name } }
                Button("Random") { roster.shuffle() }
            } label: {
                barLabel("arrow.up.arrow.down")
            }
            Spacer()
            if roster.count >= largeGameThreshold {
                Button { showWarningNote = true } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Palette.danger)
                        .frame(width: 40, height: 40)
                        .background(Palette.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.danger.opacity(0.5), lineWidth: 1))
                }
                .alert("Big game ahead", isPresented: $showWarningNote) {
                    Button("Got it", role: .cancel) { }
                } message: {
                    Text("10+ players means a longer game — make sure you've got 45+ minutes of daylight.")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private func barButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { barLabel(symbol) }
    }
    private func barLabel(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Palette.cream)
            .frame(width: 40, height: 40)
            .background(Palette.cream.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.cream.opacity(0.14), lineWidth: 1))
    }

    // MARK: Add + autocomplete

    private var addRow: some View {
        HStack(spacing: 9) {
            TextField("", text: $draft, prompt: Text("Add a player…").foregroundColor(Palette.sage))
                .font(.suseSemiBold(16))
                .foregroundStyle(Palette.cream)
                .padding(15)
                .background(Palette.cream.opacity(0.07), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.cream.opacity(0.16), lineWidth: 1))
                .submitLabel(.done)
                .onSubmit { commitDraft() }
            Button { commitDraft() } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Palette.forest)
                    .frame(width: 52, height: 52)
                    .background(Palette.lime, in: RoundedRectangle(cornerRadius: 13))
            }
        }
        .padding(.horizontal, 22)
    }

    private var matches: [Player] {
        let chosen = Set(roster.map { $0.name.lowercased() })
        return players.filter {
            !chosen.contains($0.name.lowercased()) &&
            (draft.isEmpty || $0.name.localizedCaseInsensitiveContains(draft))
        }
    }

    @ViewBuilder private var suggestions: some View {
        if !draft.isEmpty && !matches.isEmpty {
            VStack(spacing: 0) {
                ForEach(matches.prefix(5)) { player in
                    Button { add(player.name, lastPlayedAt: player.lastPlayedAt) } label: {
                        HStack(spacing: 12) {
                            InitialsBadge(name: player.name, size: 34)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(player.name).font(.suseSemiBold(15)).foregroundStyle(Palette.ink)
                                Text(lastPlayedText(player.lastPlayedAt))
                                    .font(.suseExtraLight(11.5)).foregroundStyle(Palette.inkSoft)
                            }
                            Spacer()
                            Image(systemName: "plus").foregroundStyle(Palette.forest)
                        }
                        .padding(.horizontal, 15).padding(.vertical, 11)
                    }
                    if player.id != matches.prefix(5).last?.id {
                        Divider().overlay(Palette.creamShade)
                    }
                }
            }
            .background(Palette.cream, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 22)
            .padding(.top, 8)
        }
    }

    // MARK: Roster list

    private var rosterList: some View {
        List {
            ForEach(Array(roster.enumerated()), id: \.element.id) { index, entry in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.molkkyHeader(26))
                        .foregroundStyle(Palette.lime)
                        .frame(width: 26)
                    InitialsBadge(name: entry.name, size: 38)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.name).font(.suseSemiBold(16)).foregroundStyle(Palette.cream)
                        if let lp = entry.lastPlayedAt {
                            Text("Last played \(lastPlayedText(lp))")
                                .font(.suseExtraLight(11.5)).foregroundStyle(Palette.sage)
                        }
                    }
                    Spacer()
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Palette.pine)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.lime.opacity(0.14), lineWidth: 1))
                        .padding(.vertical, 4)
                )
                .listRowSeparator(.hidden)
            }
            .onMove { roster.move(fromOffsets: $0, toOffset: $1) }
            .onDelete { roster.remove(atOffsets: $0) }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 10) {
            Text(footerHint)
                .font(.suseExtraLight(12.5))
                .foregroundStyle(Palette.sage)
            BatonSaveButton(enabled: roster.count >= 2) { startGame() }
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(Palette.forest)
    }

    private var footerHint: String {
        switch roster.count {
        case 0: return "Add a few players to start"
        case 1: return "Add at least 2 players to throw"
        default: return "\(roster.count) players · throwing in this order"
        }
    }

    // MARK: Actions

    private func commitDraft() {
        let name = draft.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        add(name, lastPlayedAt: matchedLastPlayed(name))
        draft = ""
    }

    private func add(_ name: String, lastPlayedAt: Date?) {
        guard !roster.contains(where: { $0.name.lowercased() == name.lowercased() }) else { return }
        // Slide the new card up into place (~200ms ease-in-out).
        withAnimation(.easeInOut(duration: 0.2)) {
            roster.append(RosterEntry(name: name, lastPlayedAt: lastPlayedAt))
        }
        draft = ""
    }

    private func entry(for name: String) -> RosterEntry {
        RosterEntry(name: name, lastPlayedAt: matchedLastPlayed(name))
    }
    private func matchedLastPlayed(_ name: String) -> Date? {
        players.first { $0.name.lowercased() == name.lowercased() }?.lastPlayedAt
    }
    private func lastPlayedText(_ date: Date?) -> String {
        guard let date else { return "New player" }
        return date.formatted(.relative(presentation: .named))
    }

    private func startGame() {
        guard roster.count >= 2 else { return }
        let game = Game(rules: .standard)
        context.insert(game)
        for (index, entry) in roster.enumerated() {
            let participant = GameParticipant(name: entry.name, order: index, isFirstTimer: entry.isFirstTimer)
            context.insert(participant)
            participant.game = game   // sets the inverse; SwiftData populates game.participants
            upsertPlayer(named: entry.name)
        }
        try? context.save()
        path.append(.scoring(game.persistentModelID))
    }

    private func upsertPlayer(named name: String) {
        if let existing = players.first(where: { $0.name.lowercased() == name.lowercased() }) {
            existing.lastPlayedAt = .now
        } else {
            context.insert(Player(name: name, lastPlayedAt: .now))
        }
    }
}

/// The hand-holding-the-baton save button that tosses the baton on tap.
struct BatonSaveButton: View {
    let enabled: Bool
    let action: () -> Void
    @State private var tossing = false

    var body: some View {
        Button {
            guard enabled else { return }
            withAnimation(.easeIn(duration: 0.5)) { tossing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) {
                tossing = false
                action()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "hand.point.up.braille.fill")
                    .rotationEffect(.degrees(tossing ? 520 : 0))
                    .offset(x: tossing ? 220 : 0, y: tossing ? -260 : 0)
                    .opacity(tossing ? 0 : 1)
                Text("Throw to start")
            }
            .font(.suseExtraBold(16))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(Palette.forest)
            .background(Palette.lime, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(enabled ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

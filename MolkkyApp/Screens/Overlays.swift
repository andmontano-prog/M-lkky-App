import SwiftUI
import SwiftData

// MARK: - Win celebration

struct WinOverlay: View {
    let name: String
    let reason: String
    let onDone: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Palette.lime.ignoresSafeArea()
            Confetti()
            VStack(spacing: 4) {
                Text("Game · Set · Match")
                    .font(.suseExtraBold(13)).tracking(3)
                    .foregroundStyle(Palette.forest)
                // The winner's name is the hero — script font, animated in with a
                // playful rotate + scale.
                Text(name)
                    .font(.molkkyHeader(72))
                    .foregroundStyle(Palette.forest)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 12)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .rotationEffect(.degrees(appeared ? -3 : -14))
                    .opacity(appeared ? 1 : 0)
                Text("Winner")
                    .font(.suseExtraBold(14)).tracking(3).textCase(.uppercase)
                    .foregroundStyle(Palette.forest)
                Text(reason)
                    .font(.suseExtraLight(15)).foregroundStyle(Palette.forest.opacity(0.75))
                Button(action: onDone) {
                    Text("Back to home")
                        .font(.suseExtraBold(16))
                        .frame(maxWidth: 230)
                        .padding(.vertical, 16)
                        .foregroundStyle(Palette.lime)
                        .background(Palette.forest, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.top, 26)
            }
            .padding(30)
        }
        .transition(.opacity)
        .onAppear {
            appeared = false
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) { appeared = true }
        }
    }
}

private struct Confetti: View {
    // Multi-green + yellow.
    private let colors: [Color] = [
        Palette.lime, Color(hex: 0xC4DE1E), Color(hex: 0x7ED33F),
        Color(hex: 0x16563F), Color(hex: 0xEEFF74), Palette.cream
    ]
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<44, id: \.self) { i in
                    ConfettiPiece(color: colors[i % 6], width: geo.size.width, height: geo.size.height, seed: i)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ConfettiPiece: View {
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let seed: Int
    @State private var drop = false

    var body: some View {
        let x = CGFloat((seed * 47) % 100) / 100 * width
        let size = CGFloat(8 + (seed % 5) * 2)
        let round = seed % 5 < 2
        Group {
            if round {
                Circle().fill(color).frame(width: size, height: size)
            } else {
                RoundedRectangle(cornerRadius: 2).fill(color).frame(width: size, height: size * 1.6)
            }
        }
        .rotationEffect(.degrees(Double(seed) * 37))
        .position(x: x, y: drop ? height + 40 : -40)
        .opacity(drop ? 0.55 : 1)
        .onAppear {
            withAnimation(.easeIn(duration: 1.6 + Double(seed % 5) * 0.25).delay(Double(seed % 7) * 0.06)) {
                drop = true
            }
        }
    }
}

// MARK: - In-game rules sheet

struct RulesSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Color(hex: 0xCFCDC2)).frame(width: 40, height: 5)
                .frame(maxWidth: .infinity).padding(.top, 8).padding(.bottom, 14)
            Text("Game rules").font(.molkkyHeader(36)).foregroundStyle(Palette.forest)
            Text("Tweak the house rules — just for this game.")
                .font(.suseExtraLight(13)).foregroundStyle(Palette.inkSoft)
                .padding(.bottom, 8)

            stepper("Score to win", "Reach it exactly",
                    value: game.ruleScoreToWin,
                    onChange: { game.ruleScoreToWin = max(10, min(100, game.ruleScoreToWin + $0 * 5)); save() })
            stepper("Overshoot resets to", "Go over, drop to this",
                    value: game.ruleOvershootReset,
                    onChange: { game.ruleOvershootReset = max(0, min(game.ruleScoreToWin - 5, game.ruleOvershootReset + $0 * 5)); save() })
            stepper("Strikes before out", "Misses in a row",
                    value: game.ruleStrikesToEliminate,
                    onChange: { game.ruleStrikesToEliminate = max(1, min(6, game.ruleStrikesToEliminate + $0)); save() })

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("First-timer gets +1 strike").font(.suseSemiBold(15)).foregroundStyle(Palette.ink)
                    Text("Show a checkmark on new players").font(.suseExtraLight(12)).foregroundStyle(Palette.inkSoft)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { game.ruleFirstTimerExtraStrikes > 0 },
                    set: { game.ruleFirstTimerExtraStrikes = $0 ? 1 : 0; save() }
                ))
                .labelsHidden()
                .tint(Palette.forest)
            }
            .padding(.vertical, 14)

            PrimaryButton(title: "Done") { dismiss() }
                .padding(.top, 6)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 24)
        .background(Palette.cream)
    }

    private func stepper(_ title: String, _ subtitle: String, value: Int, onChange: @escaping (Int) -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.suseSemiBold(15)).foregroundStyle(Palette.ink)
                Text(subtitle).font(.suseExtraLight(12)).foregroundStyle(Palette.inkSoft)
            }
            Spacer()
            HStack(spacing: 2) {
                stepButton("minus") { onChange(-1) }
                Text("\(value)").font(.suseExtraBold(16)).foregroundStyle(Palette.forest)
                    .frame(minWidth: 38).monospacedDigit()
                stepButton("plus") { onChange(1) }
            }
            .padding(3)
            .background(Palette.creamShade, in: RoundedRectangle(cornerRadius: 11))
        }
        .padding(.vertical, 12)
        .overlay(Divider().overlay(Palette.creamShade), alignment: .bottom)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.forest)
                .frame(width: 34, height: 34)
                .background(Palette.cream, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private func save() { try? context.save() }
}

// MARK: - Standings ("here's where we are")

struct StandingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let game: Game

    private struct Standing: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let score: Int
        let isOut: Bool
    }

    private var ranked: [Standing] {
        let rules = game.rules
        return game.orderedParticipants.map { p in
            let s = p.state(rules: rules)
            return Standing(id: p.persistentModelID, name: p.name, score: s.score, isOut: s.isEliminated)
        }
        // active players by points descending, eliminated sink to the bottom
        .sorted { a, b in
            if a.isOut != b.isOut { return !a.isOut }
            return a.score > b.score
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Color(hex: 0xCFCDC2)).frame(width: 40, height: 5)
                .frame(maxWidth: .infinity).padding(.top, 8).padding(.bottom, 12)
            Text("Standings").font(.molkkyHeader(38)).foregroundStyle(Palette.forest)
            Text("Round \(game.round) · here's where we are.")
                .font(.suseExtraLight(13)).foregroundStyle(Palette.inkSoft)
                .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(ranked.enumerated()), id: \.element.id) { index, s in
                        StandingRow(rank: index + 1, standing: s, target: game.rules.scoreToWin, isLeader: index == 0 && !s.isOut)
                    }
                }
            }

            PrimaryButton(title: "Back to game") { dismiss() }
                .padding(.top, 12)
        }
        .padding(.horizontal, 22).padding(.bottom, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.cream)
    }

    private struct StandingRow: View {
        let rank: Int
        let standing: Standing
        let target: Int
        let isLeader: Bool

        var body: some View {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(.molkkyHeader(38))
                    .foregroundStyle(isLeader ? Palette.forest : Palette.gray)
                    .frame(width: 44, alignment: .center)
                InitialsBadge(name: standing.name, size: 36)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(standing.name).font(.suseExtraBold(15)).foregroundStyle(Palette.ink)
                        if standing.isOut {
                            Text("OUT").font(.suseExtraBold(10)).foregroundStyle(Palette.danger).tracking(1)
                        }
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Palette.creamShade)
                            Capsule().fill(Palette.forest)
                                .frame(width: geo.size.width * CGFloat(min(1, Double(standing.score) / Double(max(target, 1)))))
                        }
                    }
                    .frame(height: 8)
                }
                Text("\(standing.score)")
                    .font(.suseExtraBold(26)).foregroundStyle(Palette.forest)
                    .monospacedDigit().frame(minWidth: 44, alignment: .trailing)
            }
            .padding(.vertical, 11)
            .opacity(standing.isOut ? 0.5 : 1)
            .overlay(Rectangle().fill(Palette.creamShade).frame(height: 1), alignment: .bottom)
        }
    }
}

// MARK: - Game menu (in-game management)

struct GameMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    let round: Int
    let onAdd: () -> Void
    let onRestart: () -> Void
    let onHome: () -> Void
    let onEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Capsule().fill(Color(hex: 0xCFCDC2)).frame(width: 40, height: 5)
                .frame(maxWidth: .infinity).padding(.top, 8).padding(.bottom, 10)
            Text("Game menu").font(.molkkyHeader(36)).foregroundStyle(Palette.forest)
            Text("Round \(round) in progress.").font(.suseExtraLight(13)).foregroundStyle(Palette.inkSoft)
                .padding(.bottom, 8)

            row("plus", "Add a player") { dismiss(); onAdd() }
            row("arrow.counterclockwise", "Restart game", detail: "clear scores") { dismiss(); onRestart() }
            row("house", "Back to home", detail: "game is saved") { dismiss(); onHome() }
            row("xmark", "End game & discard", danger: true) { dismiss(); onEnd() }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.cream)
    }

    private func row(_ icon: String, _ title: String, detail: String? = nil, danger: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 15, weight: .bold))
                Text(title).font(.suseExtraBold(15))
                Spacer()
                if let detail { Text(detail).font(.suseExtraLight(12)).foregroundStyle(Palette.inkSoft) }
            }
            .foregroundStyle(danger ? Palette.danger : Palette.ink)
            .padding(15)
            .background(Palette.creamShade, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add player mid-game

struct AddPlayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Player.name) private var players: [Player]
    let existingNames: [String]
    let onAdd: (String) -> Void
    @State private var draft = ""

    private var existingLower: Set<String> { Set(existingNames.map { $0.lowercased() }) }
    private var suggestions: [Player] {
        players.filter {
            !existingLower.contains($0.name.lowercased()) &&
            (draft.isEmpty || $0.name.localizedCaseInsensitiveContains(draft))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Capsule().fill(Color(hex: 0xCFCDC2)).frame(width: 40, height: 5)
                .frame(maxWidth: .infinity).padding(.top, 8).padding(.bottom, 6)
            Text("Add a player").font(.molkkyHeader(36)).foregroundStyle(Palette.forest)
            Text("They join at the end of the throw order.").font(.suseExtraLight(13)).foregroundStyle(Palette.inkSoft)

            HStack(spacing: 9) {
                TextField("", text: $draft, prompt: Text("Player name…").foregroundColor(Palette.gray))
                    .font(.suseSemiBold(16)).foregroundStyle(Palette.ink)
                    .padding(14)
                    .background(Palette.creamShade, in: RoundedRectangle(cornerRadius: 13))
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(commit)
                Button(action: commit) {
                    Image(systemName: "plus").font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Palette.forest).frame(width: 50, height: 50)
                        .background(Palette.lime, in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(suggestions.prefix(6)) { player in
                        Button { add(player.name) } label: {
                            HStack(spacing: 12) {
                                InitialsBadge(name: player.name, size: 32)
                                Text(player.name).font(.suseSemiBold(14)).foregroundStyle(Palette.ink)
                                Spacer()
                                Image(systemName: "plus").foregroundStyle(Palette.forest)
                            }
                            .padding(.horizontal, 13).padding(.vertical, 10)
                            .background(Palette.creamShade, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.cream)
    }

    private func commit() { add(draft) }
    private func add(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onAdd(trimmed)
        dismiss()
    }
}

// MARK: - Rename mid-game

struct RenameSheet: View {
    @Environment(\.dismiss) private var dismiss
    let currentName: String
    let onSave: (String) -> Void
    @State private var text: String

    init(currentName: String, onSave: @escaping (String) -> Void) {
        self.currentName = currentName
        self.onSave = onSave
        _text = State(initialValue: currentName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Capsule().fill(Color(hex: 0xCFCDC2)).frame(width: 40, height: 5)
                .frame(maxWidth: .infinity).padding(.top, 8).padding(.bottom, 6)
            Text("Rename player").font(.molkkyHeader(36)).foregroundStyle(Palette.forest)
            Text("Fix a typo or swap in a nickname — scores stay put.")
                .font(.suseExtraLight(13)).foregroundStyle(Palette.inkSoft)
            HStack(spacing: 9) {
                TextField("", text: $text)
                    .font(.suseSemiBold(16)).foregroundStyle(Palette.ink)
                    .padding(14)
                    .background(Palette.creamShade, in: RoundedRectangle(cornerRadius: 13))
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(save)
                Button(action: save) {
                    Image(systemName: "checkmark").font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Palette.forest).frame(width: 50, height: 50)
                        .background(Palette.lime, in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.cream)
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
        dismiss()
    }
}

// MARK: - Resume prompt

struct ResumePromptView: View {
    @Environment(\.dismiss) private var dismiss
    let game: Game
    let onContinue: () -> Void
    let onStartOver: () -> Void

    private var leaderText: String {
        let rules = game.rules
        if let leader = game.orderedParticipants.max(by: { $0.state(rules: rules).score < $1.state(rules: rules).score }) {
            return "\(leader.name) was leading at \(leader.state(rules: rules).score)."
        }
        return "Pick up where you left off."
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "pause.circle")
                .font(.system(size: 40)).foregroundStyle(Palette.lime).padding(.top, 6)
            Text("Welcome\nback")
                .font(.molkkyHeader(42)).foregroundStyle(Palette.lime)
                .multilineTextAlignment(.center).lineSpacing(-6)
            Text("You left a game in progress.\n\(leaderText)")
                .font(.suseExtraLight(14)).foregroundStyle(Palette.sage)
                .multilineTextAlignment(.center)
                .padding(.bottom, 14)
            PrimaryButton(title: "Continue game", action: onContinue)
            GhostButton(title: "Start over", action: onStartOver)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.forest)
    }
}

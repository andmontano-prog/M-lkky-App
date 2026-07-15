import SwiftUI
import SwiftData

struct ScoringView: View {
    @Environment(\.modelContext) private var context
    let game: Game
    @Binding var path: [GameFlow]

    @State private var controller: GameController?
    @State private var showRules = false
    @State private var editing: EditTarget?

    private struct EditTarget: Equatable {
        let participantID: PersistentIdentifier
        let index: Int
    }

    var body: some View {
        ZStack {
            MolkkyBackground()
            if let controller {
                content(controller)
                if let champ = controller.winner {
                    WinOverlay(name: champ.name, reason: controller.winReason) {
                        path.removeAll()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if controller == nil {
                controller = GameController(game: game, context: context)
            }
        }
        .sheet(isPresented: $showRules) {
            RulesSheet(game: game)
                .presentationDetents([.height(430)])
        }
    }

    private func content(_ controller: GameController) -> some View {
        VStack(spacing: 0) {
            header(controller)
            playerList(controller)
            historyStrip(controller)
            ScorePad(
                onValue: { value in
                    if let editing {
                        if let p = context.model(for: editing.participantID) as? GameParticipant {
                            controller.editThrow(for: p, at: editing.index, to: value)
                        }
                        self.editing = nil
                    } else {
                        controller.recordThrow(value)
                    }
                },
                onUndo: {
                    if editing != nil { editing = nil } else { controller.undoLastThrow() }
                }
            )
        }
    }

    // MARK: Header

    private func header(_ controller: GameController) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Now throwing · Round \(game.round)")
                        .molkkyLabel()
                    Text(controller.current?.name ?? "—")
                        .font(.molkkyHeader(40))
                        .foregroundStyle(Palette.lime)
                }
                Spacer()
                Button { showRules = true } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Palette.cream)
                        .frame(width: 42, height: 42)
                        .background(Palette.cream.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.cream.opacity(0.14), lineWidth: 1))
                }
            }
            if game.ruleFirstTimerExtraStrikes > 0, let current = controller.current {
                Button {
                    controller.setFirstTimer(current, !current.isFirstTimer)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: current.isFirstTimer ? "checkmark.square.fill" : "square")
                            .foregroundStyle(current.isFirstTimer ? Palette.lime : Palette.sage)
                        Text("First-time player — give \(current.name.split(separator: " ").first.map(String.init) ?? current.name) +\(game.ruleFirstTimerExtraStrikes) strike")
                            .font(.suseSemiBold(12.5))
                            .foregroundStyle(Palette.sage)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: Players

    private func playerList(_ controller: GameController) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(game.orderedParticipants.enumerated()), id: \.element.persistentModelID) { index, participant in
                    ScoreRow(
                        participant: participant,
                        rules: game.rules,
                        isCurrent: index == game.currentTurnIndex && !participant.state(rules: game.rules).isEliminated
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 2)
        }
    }

    // MARK: History strip

    private func historyStrip(_ controller: GameController) -> some View {
        let current = controller.current
        let state = current?.state(rules: game.rules)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                Text("History").molkkyLabel()
                if let current, current.throwValues.isEmpty {
                    Text("no throws yet — tap a number below")
                        .font(.suseExtraLight(11))
                        .foregroundStyle(Palette.sage)
                }
                if let current {
                    ForEach(Array(current.throwValues.enumerated()), id: \.offset) { idx, value in
                        let isReset = state?.resetThrowIndices.contains(idx) ?? false
                        Button {
                            editing = EditTarget(participantID: current.persistentModelID, index: idx)
                        } label: {
                            ThrowChip(value: value, isReset: isReset,
                                      isEditing: editing?.participantID == current.persistentModelID && editing?.index == idx)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Score row

struct ScoreRow: View {
    let participant: GameParticipant
    let rules: RuleConfig
    let isCurrent: Bool

    private var state: PlayerScoreState { participant.state(rules: rules) }
    private var allowed: Int { ScoringEngine.maxStrikes(rules: rules, isFirstTimer: participant.isFirstTimer) }

    var body: some View {
        HStack(spacing: 12) {
            InitialsBadge(name: participant.name, highlighted: isCurrent, size: 40)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Text(participant.name).font(.suseExtraBold(15)).foregroundStyle(Palette.cream)
                    if participant.isFirstTimer {
                        Text("+\(rules.firstTimerExtraStrikes)")
                            .font(.suseSemiBold(10))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Palette.lime, in: RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(Palette.forest)
                    }
                    HStack(spacing: 3) {
                        ForEach(0..<allowed, id: \.self) { i in
                            Circle()
                                .fill(i < state.missStreak ? Palette.danger : Palette.cream.opacity(0.18))
                                .frame(width: 7, height: 7)
                        }
                    }
                    if state.isEliminated {
                        Text("OUT").font(.suseExtraBold(10)).foregroundStyle(Palette.danger).tracking(1)
                    }
                }
                RunMeter(score: state.score, target: rules.scoreToWin)
            }
            Spacer(minLength: 8)
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text("\(state.score)")
                    .font(.suseExtraBold(26))
                    .foregroundStyle(state.isEliminated ? Palette.danger : Palette.cream)
                    .monospacedDigit()
                Text("/\(rules.scoreToWin)").font(.suseExtraLight(12)).foregroundStyle(Palette.sage)
            }
        }
        .padding(11)
        .background(isCurrent ? Palette.pineLift : Palette.pine, in: RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isCurrent ? Palette.lime : .clear, lineWidth: 1.5)
        )
        .opacity(state.isEliminated ? 0.45 : 1)
    }
}

// MARK: - Throw chip

struct ThrowChip: View {
    let value: Int
    let isReset: Bool
    let isEditing: Bool
    var body: some View {
        Text(value == 0 ? "✕" : "\(value)")
            .font(.suseExtraBold(14))
            .monospacedDigit()
            .foregroundStyle(value == 0 ? Palette.sage : (isReset ? Palette.danger : Palette.cream))
            .frame(minWidth: 34, minHeight: 34)
            .background(Palette.cream.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isEditing ? Palette.lime : (isReset ? Palette.danger : Palette.cream.opacity(0.14)),
                            lineWidth: isEditing ? 2 : 1)
            )
    }
}

// MARK: - Score pad

struct ScorePad: View {
    let onValue: (Int) -> Void
    let onUndo: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...12, id: \.self) { n in
                    Button { onValue(n) } label: {
                        Text("\(n)")
                            .font(.suseExtraBold(22))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .foregroundStyle(Palette.cream)
                            .background(n == 12 ? Palette.teal : Palette.pine,
                                        in: RoundedRectangle(cornerRadius: 13))
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack(spacing: 8) {
                Button { onValue(0) } label: {
                    Text("MISS")
                        .font(.suseExtraBold(18))
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .foregroundStyle(Palette.sage)
                        .background(Palette.cream.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.cream.opacity(0.14), lineWidth: 1))
                }
                .buttonStyle(.plain)
                Button { onUndo() } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.suseExtraBold(16))
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .foregroundStyle(Palette.lime)
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.lime.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Palette.forestDeep)
    }
}

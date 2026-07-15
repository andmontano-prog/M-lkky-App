import SwiftUI
import SwiftData

struct ScoringView: View {
    @Environment(\.modelContext) private var context
    let game: Game
    @Binding var path: [GameFlow]

    @State private var controller: GameController?
    @State private var showRules = false
    /// The points pad is hidden by default (a deliberate pause between throwers,
    /// which cuts accidental taps and gives the scorekeeper a beat to review the
    /// board). It appears only when armed for a throw or an edit.
    @State private var armed = false
    @State private var editing: EditTarget?
    @State private var expandedID: PersistentIdentifier?

    struct EditTarget: Equatable {
        let participantID: PersistentIdentifier
        let index: Int
        let previous: Int
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
                expandedID = game.currentParticipant?.persistentModelID
            }
        }
        .sheet(isPresented: $showRules) {
            RulesSheet(game: game).presentationDetents([.height(430)])
        }
    }

    private func content(_ controller: GameController) -> some View {
        VStack(spacing: 0) {
            header(controller)
            playerList(controller)
            padArea(controller)
        }
    }

    // MARK: Header

    private func header(_ controller: GameController) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Now throwing · Round \(game.round)").molkkyLabel()
                    Text(controller.current?.name ?? "—")
                        .font(.molkkyHeader(40)).foregroundStyle(Palette.lime)
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
                        Text("First-time player — give \(firstName(current.name)) +\(game.ruleFirstTimerExtraStrikes) strike")
                            .font(.suseSemiBold(12.5)).foregroundStyle(Palette.sage)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: Players (tap a row to reveal & fix throws)

    private func playerList(_ controller: GameController) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(game.orderedParticipants.enumerated()), id: \.element.persistentModelID) { index, participant in
                    ScoreRow(
                        participant: participant,
                        rules: game.rules,
                        isCurrent: index == game.currentTurnIndex && !participant.state(rules: game.rules).isEliminated,
                        isExpanded: expandedID == participant.persistentModelID,
                        onToggle: {
                            let id = participant.persistentModelID
                            expandedID = (expandedID == id) ? nil : id
                        },
                        onEditThrow: { throwIndex, previous in
                            editing = EditTarget(participantID: participant.persistentModelID, index: throwIndex, previous: previous)
                            armed = false
                            expandedID = participant.persistentModelID
                        }
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 2)
        }
    }

    // MARK: Pad area — hidden until armed / editing

    @ViewBuilder
    private func padArea(_ controller: GameController) -> some View {
        if !armed && editing == nil {
            ReadyPanel(name: firstName(controller.current?.name ?? "")) {
                armed = true
            }
        } else {
            ScorePad(
                contextText: padContext(controller),
                onValue: { value in
                    if let e = editing {
                        if let p = context.model(for: e.participantID) as? GameParticipant {
                            controller.editThrow(for: p, at: e.index, to: value)
                        }
                        editing = nil
                    } else {
                        controller.recordThrow(value)
                        armed = false
                        expandedID = controller.current?.persistentModelID
                    }
                },
                onCancel: {
                    armed = false
                    editing = nil
                }
            )
        }
    }

    private func padContext(_ controller: GameController) -> AttributedString {
        if let e = editing, let p = context.model(for: e.participantID) as? GameParticipant {
            let was = e.previous == 0 ? "miss" : "\(e.previous)"
            return AttributedString("Editing \(firstName(p.name)) · throw \(e.index + 1) (was \(was))")
        }
        return AttributedString("Scoring \(firstName(controller.current?.name ?? ""))")
    }

    private func firstName(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}

// MARK: - Score row (expandable to edit any player's throws)

struct ScoreRow: View {
    let participant: GameParticipant
    let rules: RuleConfig
    let isCurrent: Bool
    let isExpanded: Bool
    let onToggle: () -> Void
    let onEditThrow: (Int, Int) -> Void

    private var state: PlayerScoreState { participant.state(rules: rules) }
    private var allowed: Int { ScoringEngine.maxStrikes(rules: rules, isFirstTimer: participant.isFirstTimer) }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) { rowFace }
                .buttonStyle(.plain)
            if isExpanded { throwsStrip }
        }
        .background(isCurrent ? Palette.pineLift : Palette.pine, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(isCurrent ? Palette.lime : .clear, lineWidth: 1.5))
        .opacity(state.isEliminated ? 0.45 : 1)
    }

    private var rowFace: some View {
        HStack(spacing: 12) {
            InitialsBadge(name: participant.name, highlighted: isCurrent, size: 40)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Text(participant.name).font(.suseExtraBold(15)).foregroundStyle(Palette.cream)
                    if participant.isFirstTimer {
                        Text("+\(rules.firstTimerExtraStrikes)")
                            .font(.suseSemiBold(10)).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Palette.lime, in: RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(Palette.forest)
                    }
                    HStack(spacing: 3) {
                        ForEach(0..<allowed, id: \.self) { i in
                            Circle().fill(i < state.missStreak ? Palette.danger : Palette.cream.opacity(0.18))
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
                Text("\(state.score)").font(.suseExtraBold(26))
                    .foregroundStyle(state.isEliminated ? Palette.danger : Palette.cream).monospacedDigit()
                Text("/\(rules.scoreToWin)").font(.suseExtraLight(12)).foregroundStyle(Palette.sage)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isExpanded ? Palette.lime : Palette.sage)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .padding(11)
    }

    private var throwsStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(participant.name.split(separator: " ").first.map(String.init) ?? participant.name)'s throws · tap to fix")
                .molkkyLabel()
            if participant.throwValues.isEmpty {
                Text("No throws yet").font(.suseExtraLight(12)).foregroundStyle(Palette.sage)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(participant.throwValues.enumerated()), id: \.offset) { idx, value in
                            Button {
                                onEditThrow(idx, value)
                            } label: {
                                ThrowChip(value: value, isReset: state.resetThrowIndices.contains(idx), isEditing: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

// MARK: - Throw chip

struct ThrowChip: View {
    let value: Int
    let isReset: Bool
    let isEditing: Bool
    var body: some View {
        Text(value == 0 ? "✕" : "\(value)")
            .font(.suseExtraBold(14)).monospacedDigit()
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

// MARK: - Ready panel (the pause between throwers)

struct ReadyPanel: View {
    let name: String
    let onArm: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            Button(action: onArm) {
                HStack(spacing: 10) {
                    Image(systemName: "hand.point.up.braille.fill")
                    Text("Enter \(name)'s throw")
                }
                .font(.suseExtraBold(17))
                .frame(maxWidth: .infinity).padding(.vertical, 17)
                .foregroundStyle(Palette.forest)
                .background(Palette.lime, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            Text("Review the board · tap a player to fix a score")
                .font(.suseExtraLight(12)).foregroundStyle(Palette.sage)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Palette.forestDeep)
    }
}

// MARK: - Score pad (0–12, no undo — mistakes are fixed by editing)

struct ScorePad: View {
    let contextText: AttributedString
    let onValue: (Int) -> Void
    let onCancel: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(contextText).font(.suseSemiBold(12.5)).foregroundStyle(Palette.cream)
                Spacer()
                Button(action: onCancel) {
                    Text("Cancel").font(.suseSemiBold(12.5)).foregroundStyle(Palette.sage)
                        .padding(.horizontal, 13).padding(.vertical, 7)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Palette.cream.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...12, id: \.self) { n in
                    Button { onValue(n) } label: {
                        Text("\(n)").font(.suseExtraBold(22)).monospacedDigit()
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .foregroundStyle(Palette.cream)
                            .background(n == 12 ? Palette.teal : Palette.pine, in: RoundedRectangle(cornerRadius: 13))
                    }
                    .buttonStyle(.plain)
                }
            }
            Button { onValue(0) } label: {
                Text("MISS").font(.suseExtraBold(18))
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .foregroundStyle(Palette.sage)
                    .background(Palette.cream.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.cream.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Palette.forestDeep)
    }
}

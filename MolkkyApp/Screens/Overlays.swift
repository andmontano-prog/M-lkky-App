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

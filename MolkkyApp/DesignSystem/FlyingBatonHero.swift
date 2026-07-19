import SwiftUI

/// Home-screen mascot — the same baton as the launch splash (solid lime
/// rounded-rectangle pill, closed happy eyes, trailing motion lines). Flies
/// in from the left on appear and settles.
struct FlyingBatonHero: View {
    @State private var flownIn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Trailing motion lines to the left of the baton.
            Swoosh()
                .stroke(Palette.lime, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 44, height: 16)
                .offset(x: -66, y: -14)
            Swoosh()
                .stroke(Palette.lime, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 50, height: 18)
                .offset(x: -70, y: 8)

            baton
        }
        .frame(maxWidth: .infinity)
        .frame(height: 108)
        .offset(x: flownIn ? 0 : -220)
        .opacity(flownIn ? 1 : 0)
        .accessibilityHidden(true)
        .onAppear { runFlyIn() }
    }

    private var baton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.lime)
                .frame(width: 48, height: 100)
            HStack(spacing: 9) {
                eye
                eye
            }
            .offset(y: -22)
        }
        .rotationEffect(.degrees(-14))
    }

    private var eye: some View {
        EyeArc()
            .stroke(Palette.forest, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            .frame(width: 14, height: 8)
    }

    private func runFlyIn() {
        flownIn = false
        guard !reduceMotion else { flownIn = true; return }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.68).delay(0.05)) {
            flownIn = true
        }
    }
}

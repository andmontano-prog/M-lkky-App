import SwiftUI

/// The home-screen mascot: a smiling Mölkky baton mid-flight, with speed
/// streaks and a dotted motion arc. On appear it flies in from the left and
/// settles into place — mirroring the app icon's "baton in motion" mark.
struct FlyingBatonHero: View {
    @State private var flownIn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pinGradient = LinearGradient(
        colors: [Color(hex: 0xF1FF95), Color(hex: 0xCFE924)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    var body: some View {
        ZStack(alignment: .center) {
            // Dotted motion arc trailing behind the baton.
            MotionArc()
                .trim(from: 0, to: flownIn ? 1 : 0)
                .stroke(Palette.lime.opacity(0.55),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [1.5, 15]))
                .frame(width: 250, height: 92)
                .offset(x: -34, y: 16)

            baton
                .offset(x: flownIn ? 46 : -230, y: -2)
                .rotationEffect(.degrees(flownIn ? -28 : -18))
                .opacity(flownIn ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 108)
        .accessibilityHidden(true)
        .onAppear { runFlyIn() }
    }

    // MARK: Baton character

    private var baton: some View {
        ZStack {
            // Speed streaks to the left of the body.
            streaks.offset(x: -46, y: 2)

            // Body.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(pinGradient)
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Palette.forest, lineWidth: 3.5))
                .frame(width: 58, height: 86)

            // Lighter cap band across the top.
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: 0xF5FFB0))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Palette.forest, lineWidth: 3.5))
                .frame(width: 58, height: 26)
                .offset(y: -30)

            face.offset(y: 6)
        }
        .frame(width: 58, height: 86)
    }

    private var streaks: some View {
        VStack(alignment: .trailing, spacing: 9) {
            Capsule().fill(Palette.lime.opacity(0.85)).frame(width: 26, height: 6)
            Capsule().fill(Palette.lime.opacity(0.85)).frame(width: 18, height: 6)
                .offset(x: -6)
        }
    }

    private var face: some View {
        ZStack {
            // Rosy cheeks.
            HStack(spacing: 30) {
                Circle().fill(Palette.danger.opacity(0.42)).frame(width: 8, height: 8)
                Circle().fill(Palette.danger.opacity(0.42)).frame(width: 8, height: 8)
            }
            .offset(y: 5)

            VStack(spacing: 7) {
                HStack(spacing: 13) {
                    Circle().fill(Palette.forest).frame(width: 8, height: 8)
                    Circle().fill(Palette.forest).frame(width: 8, height: 8)
                }
                MouthCurve(smile: true)
                    .stroke(Palette.forest, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 24, height: 10)
            }
        }
    }

    // MARK: Animation

    private func runFlyIn() {
        flownIn = false
        guard !reduceMotion else { flownIn = true; return }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.68).delay(0.05)) {
            flownIn = true
        }
    }
}

/// The dotted "in motion" arc: sweeps up from the lower-left toward the baton.
private struct MotionArc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.maxY * 0.86))
        return p
    }
}

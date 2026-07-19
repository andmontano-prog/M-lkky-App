import SwiftUI

/// Cold-launch splash: the baton mascot swooshes in from the lower-left,
/// settles, its motion lines trail behind, and its eyes pop open — then it
/// hands off to Home. Timings/easings are ported 1:1 from the Figma Smart
/// Animate timeline (Baton Club / node 68). Plays once; no loop.
struct SplashView: View {
    var onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // One @State per animated property so each can carry its own curve/delay,
    // matching the per-field keyframes from Figma.
    @State private var batonIn = false        // translate + scale + rotate entrance (0–350ms)
    @State private var batonVisible = false    // opacity 0→1 by 50ms
    @State private var eyesOpen = false        // eyes scale 0.3→1 over 1349ms
    @State private var linesIn = false         // motion lines slide right ~80px
    @State private var linesVisible = false    // motion lines opacity 0→1 at 115–164ms

    var body: some View {
        ZStack {
            Palette.forest.ignoresSafeArea()

            ZStack {
                // Motion lines (trailing speed-lines to the left of the baton).
                Swoosh()
                    .stroke(Palette.lime, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .frame(width: 64, height: 24)
                    .offset(x: -104 + (linesIn ? 0 : -80), y: -30)
                    .opacity(linesVisible ? 1 : 0)
                Swoosh()
                    .stroke(Palette.lime, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .frame(width: 72, height: 26)
                    .offset(x: -110 + (linesIn ? 0 : -80), y: 2)
                    .opacity(linesVisible ? 1 : 0)

                // Baton (pill + eyes).
                baton
                    .scaleEffect(batonIn ? 1 : 0.7)
                    .rotationEffect(.degrees(batonIn ? 0 : -25))   // extra entrance spin, unwinds to the rest tilt
                    .offset(x: batonIn ? 0 : -300, y: batonIn ? 0 : 100)
                    .opacity(batonVisible ? 1 : 0)
            }
            .offset(y: -42)   // sits just above center, matching the Figma frame
        }
        .onAppear(perform: run)
    }

    private var baton: some View {
        ZStack {
            Capsule().fill(Palette.lime).frame(width: 72, height: 150)
            HStack(spacing: 12) {
                eye
                eye
            }
            .offset(y: -34)
        }
        .rotationEffect(.degrees(-14))   // resting tilt, baked into the shape
    }

    private var eye: some View {
        EyeArc()
            .stroke(Palette.forest, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
            .frame(width: 20, height: 11)
            .scaleEffect(eyesOpen ? 1 : 0.3)
    }

    private func run() {
        guard !reduceMotion else {
            // Snap straight to the settled state, hold briefly, then hand off.
            batonIn = true; batonVisible = true; eyesOpen = true; linesIn = true; linesVisible = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: onFinish)
            return
        }
        withAnimation(.linear(duration: 0.05)) { batonVisible = true }
        withAnimation(.timingCurve(0, 0, 0, 1, duration: 0.35)) { batonIn = true }
        withAnimation(.timingCurve(0, 0, 0, 1, duration: 1.349)) { eyesOpen = true }
        withAnimation(.linear(duration: 0.05).delay(0.115)) { linesVisible = true }
        withAnimation(.timingCurve(0.2, 0, 0, 1, duration: 0.5).delay(0.115)) { linesIn = true }
        // Hand off shortly after the baton + lines have settled.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05, execute: onFinish)
    }
}

/// A closed, content eye — a shallow arc peaking upward (︿).
struct EyeArc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.minY - r.height * 0.5))
        return p
    }
}

/// A single motion / speed line — a shallow arc.
struct Swoosh: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY),
                       control: CGPoint(x: r.midX, y: r.minY))
        return p
    }
}

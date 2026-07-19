import SwiftUI

// MARK: - Screen scaffolding

/// Standard dark screen background used app-wide.
struct MolkkyBackground: View {
    var body: some View {
        Palette.forest.ignoresSafeArea()
    }
}

/// Every screen animates in: content fades + slides up ~15pt on appear.
/// (Tuned to ~280ms — a literal 2ms is imperceptible.)
struct ScreenEntrance: ViewModifier {
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 15)
            .onAppear {
                shown = false
                withAnimation(.easeOut(duration: 0.28)) { shown = true }
            }
    }
}

extension View {
    func screenEntrance() -> some View { modifier(ScreenEntrance()) }
}

/// Big signature screen title + optional subtitle.
struct ScreenTitle: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.molkkyHeader(52))
                .lineLimit(1)                  // keep long titles (e.g. Wooden Bowling) on one line
                .minimumScaleFactor(0.5)       // …shrinking to fit instead of wrapping
                .foregroundStyle(Palette.cream)
            if let subtitle {
                Text(subtitle)
                    .font(.suseExtraLight(14))
                    .foregroundStyle(Palette.sage)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.suseExtraBold(16))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(Palette.forest)
            .background(Palette.lime, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct GhostButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.suseSemiBold(15))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(Palette.cream)
                .background(Palette.cream.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Palette.cream.opacity(0.16), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Avatar

struct InitialsBadge: View {
    let name: String
    var highlighted: Bool = false
    var size: CGFloat = 40

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    var body: some View {
        Text(initials)
            .font(.suseExtraBold(size * 0.36))
            .foregroundStyle(highlighted ? Palette.forest : Palette.lime)
            .frame(width: size, height: size)
            .background(
                Circle().fill(highlighted ? Palette.lime : Palette.lime.opacity(0.16))
            )
    }
}

// MARK: - Run-to-target meter

struct RunMeter: View {
    let score: Int
    let target: Int
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.forestDeep.opacity(0.6))
                Capsule()
                    .fill(Palette.lime)
                    .frame(width: geo.size.width * CGFloat(min(1, Double(score) / Double(max(target, 1)))))
            }
        }
        .frame(height: 9)
    }
}

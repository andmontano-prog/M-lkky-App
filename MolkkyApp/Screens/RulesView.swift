import SwiftUI

/// Illustrated rules. v0.1 lays out the structure and tone; the diagrams get the
/// full Rhythm-Heaven treatment (weird, charming JP-cartoon art) in a later pass.
struct RulesView: View {
    private let steps: [(String, String, String)] = [
        ("1", "Toss the baton", "Underhand, from behind the line, at the numbered pins."),
        ("2", "Count what falls", "One pin = its number. Two or more = how many fell. Knock 12 & 3? That's 2 points."),
        ("3", "Hit exactly 50", "First to 50 wins. Go over and you drop back to 25 — so mind your aim near the top."),
        ("4", "Three misses, you're out", "Whiff three times in a row and you're eliminated. New players can earn an extra strike.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to\nplay").font(.molkkyHeader(46)).foregroundStyle(Palette.forest)
                    Text("Knock 'em down. Hit fifty. Don't overcook it.")
                        .font(.suseSemiBold(13)).foregroundStyle(Palette.forest.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background(Palette.lime, in: RoundedRectangle(cornerRadius: 20))
                .padding(.bottom, 8)

                ForEach(steps, id: \.0) { step in
                    HStack(alignment: .top, spacing: 14) {
                        Text(step.0)
                            .font(.molkkyHeader(44)).foregroundStyle(Palette.lime)
                            .frame(width: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.1).font(.suseExtraBold(16)).foregroundStyle(Palette.cream)
                            Text(step.2).font(.suseExtraLight(14)).foregroundStyle(Palette.sage)
                                .lineSpacing(3)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 16)
                    .overlay(
                        Rectangle().fill(Palette.sage.opacity(0.25)).frame(height: 1),
                        alignment: .bottom
                    )
                }

                Text("Diagrams get the full Rhythm-Heaven treatment in a later build.")
                    .font(.suseExtraLight(12)).foregroundStyle(Palette.sage)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 30)
        }
        .background(MolkkyBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

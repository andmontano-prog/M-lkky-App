import SwiftUI

/// Illustrated rules in a flat, Rhythm-Heaven-flavored cartoon style — skittles
/// with faces, motion lines, the works. Art lives in Assets.xcassets
/// (rule-toss / rule-count / rule-fifty / rule-out).
struct RulesView: View {
    private struct Rule: Identifiable {
        let id: Int
        let image: String
        let title: String
        let body: AttributedString
    }

    private let rules: [Rule] = [
        Rule(id: 1, image: "rule-toss", title: "Toss the baton",
             body: "Underhand, from behind the line, at the numbered pins."),
        Rule(id: 2, image: "rule-count", title: "Count what falls",
             body: try! AttributedString(markdown: "**One pin** = its number. **Two or more** = how many fell.")),
        Rule(id: 3, image: "rule-fifty", title: "Race to exactly 50",
             body: try! AttributedString(markdown: "First to **50** wins. Go over and you drop back to **25**.")),
        Rule(id: 4, image: "rule-out", title: "Three misses, you're out",
             body: try! AttributedString(markdown: "Whiff **three times** in a row and you're eliminated. New players can earn a fourth."))
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to\nplay").font(.molkkyHeader(46)).foregroundStyle(Palette.forest)
                    Text("Knock 'em down. Hit fifty. Don't overcook it.")
                        .font(.suseSemiBold(13)).foregroundStyle(Palette.forest.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background(Palette.lime, in: RoundedRectangle(cornerRadius: 20))

                ForEach(rules) { rule in
                    RuleCard(rule: rule)
                }

                Text("Skittles with feelings. More scenes as the game grows.")
                    .font(.suseExtraLight(12)).foregroundStyle(Palette.sage)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 30)
            .screenEntrance()
        }
        .background(MolkkyBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct RuleCard: View {
        let rule: Rule
        var body: some View {
            VStack(spacing: 0) {
                Image(rule.image)
                    .resizable()
                    .aspectRatio(3.0 / 2.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                HStack(alignment: .top, spacing: 12) {
                    Text("\(rule.id)")
                        .font(.molkkyHeader(34)).foregroundStyle(Palette.lime)
                        .frame(width: 28, alignment: .leading)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(rule.title).font(.suseExtraBold(15)).foregroundStyle(Palette.cream)
                        Text(rule.body).font(.suseExtraLight(13)).foregroundStyle(Palette.sage)
                            .tint(Palette.lime)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
            }
            .background(Palette.pine, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.lime.opacity(0.12), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}

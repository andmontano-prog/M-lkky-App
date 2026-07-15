import SwiftUI

/// Type system. Momo Signature (a signature-script face) carries page headers as
/// a flourish; SUSE handles all functional UI in three weights.
/// Font names below are the exact PostScript names baked into the TTFs in
/// Resources/Fonts — see README for how the SUSE statics were instanced.
enum Typeface {
    static let header = "Momo Signature"      // family name
    static let suseExtraLight = "SUSE-ExtraLight"
    static let suseSemiBold   = "SUSE-SemiBold"
    static let suseExtraBold  = "SUSE-ExtraBold"
}

extension Font {
    /// Big signature page/screen headers.
    static func molkkyHeader(_ size: CGFloat) -> Font {
        .custom(Typeface.header, size: size)
    }
    static func suseExtraLight(_ size: CGFloat) -> Font { .custom(Typeface.suseExtraLight, size: size) }
    static func suseSemiBold(_ size: CGFloat)   -> Font { .custom(Typeface.suseSemiBold, size: size) }
    static func suseExtraBold(_ size: CGFloat)  -> Font { .custom(Typeface.suseExtraBold, size: size) }
}

extension Text {
    /// Uppercase eyebrow / label styling used across the app.
    func molkkyLabel() -> some View {
        self.font(.suseSemiBold(11))
            .textCase(.uppercase)
            .tracking(1.6)
            .foregroundStyle(Palette.sage)
    }
}

import SwiftUI

/// Mölkky brand palette — pulled straight from the moodboard
/// (Huntington "Craft Your Money's Worth" + "The Grid" tennis-club branding).
/// Deep forest/teal grounds, electric chartreuse pop, warm cream paper.
enum Palette {
    static let forest    = Color(hex: 0x0C3B2E) // primary deep ground
    static let forestDeep = Color(hex: 0x0A2E24) // darker ground / tab bar
    static let teal      = Color(hex: 0x0B4550) // alt deep surface
    static let pine      = Color(hex: 0x0F4636) // raised green surface on dark
    static let pineLift  = Color(hex: 0x12523E) // highlighted row
    static let lime      = Color(hex: 0xE6FF4B) // electric chartreuse accent
    static let cream     = Color(hex: 0xF9F7F2) // paper
    static let creamShade = Color(hex: 0xEFEDE3)
    static let gray      = Color(hex: 0x898A8D) // muted neutral
    static let sage      = Color(hex: 0x7E9A8C) // green-biased muted text on dark
    static let mist      = Color(hex: 0xEAF0EC) // near-white body text on dark (high contrast)
    static let ink       = Color(hex: 0x0C3B2E) // text on cream
    static let inkSoft   = Color(hex: 0x4A5A52) // muted text on cream
    static let danger    = Color(hex: 0xE4572E) // elimination / delete
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

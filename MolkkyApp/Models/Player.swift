import Foundation
import SwiftData

/// A person you play with. Host-owned, lightweight — just a name plus metadata
/// that powers autocomplete and the "last played" hint. Not an account.
@Model
final class Player {
    @Attribute(.unique) var name: String
    var createdAt: Date
    var lastPlayedAt: Date?

    init(name: String, createdAt: Date = .now, lastPlayedAt: Date? = nil) {
        self.name = name
        self.createdAt = createdAt
        self.lastPlayedAt = lastPlayedAt
    }
}

import Foundation

enum ChatRole: String, Hashable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    let role: ChatRole
    let text: String
    let createdAt: Date

    init(id: UUID = UUID(), role: ChatRole, text: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

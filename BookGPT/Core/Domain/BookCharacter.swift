import Foundation

struct BookCharacter: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String

    init(id: UUID = UUID(), name: String, description: String) {
        self.id = id
        self.name = name
        self.description = description
    }
}

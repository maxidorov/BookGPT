import Foundation

struct Book: Identifiable, Hashable {
    let id: UUID
    let title: String
    let author: String

    init(id: UUID = UUID(), title: String, author: String) {
        self.id = id
        self.title = title
        self.author = author
    }
}

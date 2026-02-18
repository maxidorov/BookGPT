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

extension Book {
    var storageKey: String {
        "\(title.normalizedStoragePart)|\(author.normalizedStoragePart)"
    }
}

private extension String {
    var normalizedStoragePart: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

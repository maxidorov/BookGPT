import Foundation
import SwiftData

final class SwiftDataBookHistoryStore: BookHistoryStore {
    @Model
    final class RecentBookRecord {
        @Attribute(.unique) var key: String
        var title: String
        var author: String
        var lastOpenedAt: Date

        init(key: String, title: String, author: String, lastOpenedAt: Date) {
            self.key = key
            self.title = title
            self.author = author
            self.lastOpenedAt = lastOpenedAt
        }
    }

    @Model
    final class CharacterRecord {
        var bookKey: String
        var name: String
        var summary: String

        init(bookKey: String, name: String, summary: String) {
            self.bookKey = bookKey
            self.name = name
            self.summary = summary
        }
    }

    @Model
    final class PortraitRecord {
        @Attribute(.unique) var key: String
        var bookKey: String
        var characterName: String
        var imageData: Data

        init(key: String, bookKey: String, characterName: String, imageData: Data) {
            self.key = key
            self.bookKey = bookKey
            self.characterName = characterName
            self.imageData = imageData
        }
    }

    private let context: ModelContext
    private var recentBooksCache: [Book] = []
    private var charactersCache: [String: [BookCharacter]] = [:]
    private var portraitsCache: [String: Data] = [:]

    init() throws {
        let schema = Schema([RecentBookRecord.self, CharacterRecord.self, PortraitRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        self.context = ModelContext(container)
        self.recentBooksCache = fetchRecentBooksFromStorage()
    }

    func loadRecentBooks() -> [Book] {
        recentBooksCache
    }

    func addRecentBook(_ book: Book) {
        let key = book.storageKey

        do {
            let descriptor = FetchDescriptor<RecentBookRecord>(
                predicate: #Predicate { $0.key == key }
            )

            if let existing = try context.fetch(descriptor).first {
                existing.title = book.title
                existing.author = book.author
                existing.lastOpenedAt = Date()
            } else {
                context.insert(
                    RecentBookRecord(
                        key: key,
                        title: book.title,
                        author: book.author,
                        lastOpenedAt: Date()
                    )
                )
            }

            try context.save()
            recentBooksCache = fetchRecentBooksFromStorage()
        } catch {
            print("BookHistoryStore.addRecentBook error: \(error)")
        }
    }

    func loadCachedCharacters(for book: Book) -> [BookCharacter]? {
        let key = book.storageKey

        if let cached = charactersCache[key] {
            return cached
        }

        do {
            let descriptor = FetchDescriptor<CharacterRecord>(
                predicate: #Predicate { $0.bookKey == key }
            )
            let records = try context.fetch(descriptor)
            guard !records.isEmpty else {
                return nil
            }

            let characters = records.map {
                BookCharacter(name: $0.name, description: $0.summary)
            }
            charactersCache[key] = characters
            return characters
        } catch {
            print("BookHistoryStore.loadCachedCharacters error: \(error)")
            return nil
        }
    }

    func saveCharacters(_ characters: [BookCharacter], for book: Book) {
        let key = book.storageKey

        do {
            let descriptor = FetchDescriptor<CharacterRecord>(
                predicate: #Predicate { $0.bookKey == key }
            )
            let existing = try context.fetch(descriptor)
            for record in existing {
                context.delete(record)
            }

            for character in characters {
                context.insert(
                    CharacterRecord(
                        bookKey: key,
                        name: character.name,
                        summary: character.description
                    )
                )
            }

            try context.save()
            charactersCache[key] = characters
        } catch {
            print("BookHistoryStore.saveCharacters error: \(error)")
        }
    }

    func loadPortraitData(for character: BookCharacter, in book: Book) -> Data? {
        let key = portraitKey(for: character, in: book)
        if let cached = portraitsCache[key] {
            return cached
        }

        do {
            let descriptor = FetchDescriptor<PortraitRecord>(
                predicate: #Predicate { $0.key == key }
            )
            guard let record = try context.fetch(descriptor).first else {
                return nil
            }
            portraitsCache[key] = record.imageData
            return record.imageData
        } catch {
            print("BookHistoryStore.loadPortraitData error: \(error)")
            return nil
        }
    }

    func savePortraitData(_ data: Data, for character: BookCharacter, in book: Book) {
        let key = portraitKey(for: character, in: book)
        let bookKey = book.storageKey
        let characterName = character.name.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let descriptor = FetchDescriptor<PortraitRecord>(
                predicate: #Predicate { $0.key == key }
            )

            if let existing = try context.fetch(descriptor).first {
                existing.imageData = data
                existing.characterName = characterName
                existing.bookKey = bookKey
            } else {
                context.insert(
                    PortraitRecord(
                        key: key,
                        bookKey: bookKey,
                        characterName: characterName,
                        imageData: data
                    )
                )
            }

            try context.save()
            portraitsCache[key] = data
        } catch {
            print("BookHistoryStore.savePortraitData error: \(error)")
        }
    }

    private func fetchRecentBooksFromStorage() -> [Book] {
        do {
            var descriptor = FetchDescriptor<RecentBookRecord>(
                sortBy: [SortDescriptor(\RecentBookRecord.lastOpenedAt, order: .reverse)]
            )
            descriptor.fetchLimit = 20
            let records = try context.fetch(descriptor)
            return records.map {
                Book(title: $0.title, author: $0.author)
            }
        } catch {
            print("BookHistoryStore.fetchRecentBooksFromStorage error: \(error)")
            return []
        }
    }

    private func portraitKey(for character: BookCharacter, in book: Book) -> String {
        "\(book.storageKey)|\(character.name.normalizedStoragePart)"
    }
}

final class InMemoryBookHistoryStore: BookHistoryStore {
    private var recentBooks: [Book] = []
    private var charactersByBookKey: [String: [BookCharacter]] = [:]
    private var portraitByCharacterKey: [String: Data] = [:]

    func loadRecentBooks() -> [Book] {
        recentBooks
    }

    func addRecentBook(_ book: Book) {
        recentBooks.removeAll { $0.storageKey == book.storageKey }
        recentBooks.insert(book, at: 0)
        if recentBooks.count > 20 {
            recentBooks = Array(recentBooks.prefix(20))
        }
    }

    func loadCachedCharacters(for book: Book) -> [BookCharacter]? {
        charactersByBookKey[book.storageKey]
    }

    func saveCharacters(_ characters: [BookCharacter], for book: Book) {
        charactersByBookKey[book.storageKey] = characters
    }

    func loadPortraitData(for character: BookCharacter, in book: Book) -> Data? {
        portraitByCharacterKey[portraitKey(for: character, in: book)]
    }

    func savePortraitData(_ data: Data, for character: BookCharacter, in book: Book) {
        portraitByCharacterKey[portraitKey(for: character, in: book)] = data
    }

    private func portraitKey(for character: BookCharacter, in book: Book) -> String {
        "\(book.storageKey)|\(character.name.normalizedStoragePart)"
    }
}

private extension String {
    var normalizedStoragePart: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

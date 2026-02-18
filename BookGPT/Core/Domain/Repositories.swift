import Foundation

protocol BooksRepository {
    func searchBooks(query: String) async throws -> [Book]
}

protocol CharactersRepository {
    func characters(for book: Book) async throws -> [BookCharacter]
}

protocol CharacterChatService {
    func sendMessage(
        userText: String,
        history: [ChatMessage],
        character: BookCharacter,
        book: Book
    ) async throws -> ChatMessage
}

protocol BookHistoryStore {
    func loadRecentBooks() -> [Book]
    func addRecentBook(_ book: Book)
    func loadCachedCharacters(for book: Book) -> [BookCharacter]?
    func saveCharacters(_ characters: [BookCharacter], for book: Book)
}

import Foundation
import Combine

@MainActor
final class CharactersListViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded([BookCharacter])
        case error(String)
    }

    @Published private(set) var state: State = .loading

    private let book: Book
    private let charactersRepository: CharactersRepository
    private let historyStore: BookHistoryStore

    init(book: Book, charactersRepository: CharactersRepository, historyStore: BookHistoryStore) {
        self.book = book
        self.charactersRepository = charactersRepository
        self.historyStore = historyStore
    }

    func loadCharacters() async {
        if let cachedCharacters = historyStore.loadCachedCharacters(for: book) {
            state = .loaded(cachedCharacters)
            return
        }

        state = .loading

        do {
            let characters = try await charactersRepository.characters(for: book)
            historyStore.saveCharacters(characters, for: book)
            state = .loaded(characters)
        } catch {
            state = .error("Failed to load characters")
        }
    }
}

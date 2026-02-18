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

    init(book: Book, charactersRepository: CharactersRepository) {
        self.book = book
        self.charactersRepository = charactersRepository
    }

    func loadCharacters() async {
        state = .loading

        do {
            let characters = try await charactersRepository.characters(for: book)
            state = .loaded(characters)
        } catch {
            state = .error("Failed to load characters")
        }
    }
}

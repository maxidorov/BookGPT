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
    @Published private(set) var generatingCharacterID: UUID?
    @Published private(set) var generationErrorMessage: String?
    private var hasLoadedOnce = false

    private let book: Book
    private let charactersRepository: CharactersRepository
    private let portraitService: CharacterPortraitGenerating
    private let historyStore: BookHistoryStore

    init(
        book: Book,
        charactersRepository: CharactersRepository,
        portraitService: CharacterPortraitGenerating,
        historyStore: BookHistoryStore
    ) {
        self.book = book
        self.charactersRepository = charactersRepository
        self.portraitService = portraitService
        self.historyStore = historyStore
    }

    func loadCharacters(forceReload: Bool = false) async {
        guard forceReload || !hasLoadedOnce else { return }
        hasLoadedOnce = true

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

    func retry() async {
        await loadCharacters(forceReload: true)
    }

    func prepareCharacterForChat(_ character: BookCharacter) async -> Bool {
        generationErrorMessage = nil

        if historyStore.loadPortraitData(for: character, in: book) != nil {
            return true
        }

        generatingCharacterID = character.id
        defer { generatingCharacterID = nil }

        do {
            let data = try await portraitService.generatePortrait(for: character, in: book)
            historyStore.savePortraitData(data, for: character, in: book)
            return true
        } catch {
            generationErrorMessage = "Could not generate portrait for \(character.name). Please try again."
            return false
        }
    }
}

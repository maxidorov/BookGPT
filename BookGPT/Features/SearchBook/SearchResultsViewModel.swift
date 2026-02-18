import Foundation
import Combine

@MainActor
final class SearchResultsViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded([Book])
        case error(String)
    }

    @Published private(set) var state: State = .loading
    private var hasLoadedOnce = false

    private let query: String
    private let booksRepository: BooksRepository
    private let historyStore: BookHistoryStore

    init(query: String, booksRepository: BooksRepository, historyStore: BookHistoryStore) {
        self.query = query
        self.booksRepository = booksRepository
        self.historyStore = historyStore
    }

    func loadIfNeeded() async {
        guard !hasLoadedOnce else { return }
        await load()
    }

    func load() async {
        hasLoadedOnce = true
        state = .loading
        do {
            let books = try await booksRepository.searchBooks(query: query)
            state = .loaded(books)
        } catch {
            state = .error("Failed to search books. Try again.")
        }
    }

    func retry() async {
        await load()
    }

    func selectBook(_ book: Book) {
        historyStore.addRecentBook(book)
    }
}

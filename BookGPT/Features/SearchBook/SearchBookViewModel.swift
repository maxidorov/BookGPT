import Foundation
import Combine

@MainActor
final class SearchBookViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Book])
        case error(String)
    }

    @Published var query: String = ""
    @Published private(set) var state: State = .idle
    @Published private(set) var recentBooks: [Book] = []

    private let booksRepository: BooksRepository
    private let historyStore: BookHistoryStore

    init(booksRepository: BooksRepository, historyStore: BookHistoryStore) {
        self.booksRepository = booksRepository
        self.historyStore = historyStore
        self.recentBooks = historyStore.loadRecentBooks()
    }

    func search() async {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            state = .error("Enter a book title")
            return
        }

        state = .loading

        do {
            let books = try await booksRepository.searchBooks(query: normalizedQuery)
            state = .loaded(books)
        } catch {
            state = .error("Failed to search books. Try again.")
        }
    }

    func loadRecentBooks() {
        recentBooks = historyStore.loadRecentBooks()
    }

    func selectBook(_ book: Book) {
        historyStore.addRecentBook(book)
        recentBooks = historyStore.loadRecentBooks()
    }
}

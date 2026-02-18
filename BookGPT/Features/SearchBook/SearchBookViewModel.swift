import Foundation
import Combine

@MainActor
final class SearchBookViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var recentBooks: [Book] = []
    @Published private(set) var validationError: String?

    private let historyStore: BookHistoryStore

    init(historyStore: BookHistoryStore) {
        self.historyStore = historyStore
        self.recentBooks = historyStore.loadRecentBooks()
    }

    func validatedQueryForSearch() -> String? {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            validationError = "Enter a book title"
            return nil
        }
        validationError = nil
        return normalizedQuery
    }

    func loadRecentBooks() {
        recentBooks = historyStore.loadRecentBooks()
    }

    func selectBook(_ book: Book) {
        historyStore.addRecentBook(book)
        recentBooks = historyStore.loadRecentBooks()
    }
}

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

    private let booksRepository: BooksRepository

    init(booksRepository: BooksRepository) {
        self.booksRepository = booksRepository
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
}

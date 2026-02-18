import SwiftUI

struct AppRootView: View {
    private let dependencies: AppDependencies
    @State private var path: [AppRoute] = []

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
    }

    var body: some View {
        NavigationStack(path: $path) {
            SearchBookView(
                historyStore: dependencies.historyStore
            ) { query in
                path.append(.searchResults(query: query))
            } onBookSelected: { selectedBook in
                path.append(.characters(book: selectedBook))
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .searchResults(let query):
                    SearchResultsView(
                        query: query,
                        booksRepository: dependencies.booksRepository,
                        historyStore: dependencies.historyStore
                    ) { selectedBook in
                        path.append(.characters(book: selectedBook))
                    }
                case .characters(let book):
                    CharactersListView(
                        book: book,
                        charactersRepository: dependencies.charactersRepository,
                        historyStore: dependencies.historyStore
                    ) { selectedCharacter in
                        path.append(.chat(book: book, character: selectedCharacter))
                    }
                case .chat(let book, let character):
                    CharacterChatView(
                        chatService: dependencies.chatService,
                        book: book,
                        character: character
                    )
                }
            }
        }
        .background(BrandBook.Colors.background.ignoresSafeArea())
    }
}

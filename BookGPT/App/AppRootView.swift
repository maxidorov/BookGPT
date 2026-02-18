import SwiftUI

struct AppRootView: View {
    private let dependencies: AppDependencies
    @State private var path: [AppRoute] = []

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
    }

    var body: some View {
        NavigationStack(path: $path) {
            SearchBookView(booksRepository: dependencies.booksRepository) { selectedBook in
                path.append(.characters(book: selectedBook))
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .characters(let book):
                    CharactersListView(
                        book: book,
                        charactersRepository: dependencies.charactersRepository
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
    }
}

import SwiftUI

struct AppRootView: View {
    private let dependencies: AppDependencies
    @State private var path: [AppRoute] = []

    @AppStorage("bookgpt_has_completed_onboarding") private var hasCompletedOnboarding = false
    @AppStorage("bookgpt_is_paid_user") private var isPaidUser = false

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
    }

    var body: some View {
        Group {
            if isPaidUser {
                mainExperience
            } else {
                OnboardingFlowView(
                    startAtPaywall: hasCompletedOnboarding,
                    onReachedPaywall: {
                        hasCompletedOnboarding = true
                    },
                    onPurchaseCompleted: {
                        hasCompletedOnboarding = true
                        isPaidUser = true
                    }
                )
            }
        }
        .background(BrandBook.Colors.background.ignoresSafeArea())
    }

    private var mainExperience: some View {
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
                        portraitService: dependencies.portraitService,
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
    }
}

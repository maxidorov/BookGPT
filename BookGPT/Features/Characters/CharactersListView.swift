import SwiftUI

struct CharactersListView: View {
    @StateObject private var viewModel: CharactersListViewModel
    private let book: Book
    let onCharacterSelected: (BookCharacter) -> Void

    init(
        book: Book,
        charactersRepository: CharactersRepository,
        historyStore: BookHistoryStore,
        onCharacterSelected: @escaping (BookCharacter) -> Void
    ) {
        self.book = book
        _viewModel = StateObject(
            wrappedValue: CharactersListViewModel(
                book: book,
                charactersRepository: charactersRepository,
                historyStore: historyStore
            )
        )
        self.onCharacterSelected = onCharacterSelected
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                switch viewModel.state {
                case .loading:
                    ProgressView("Loading characters...")
                        .tint(BrandBook.Colors.gold)
                case .loaded(let characters):
                    if characters.isEmpty {
                        Text("No characters found")
                            .font(BrandBook.Typography.caption())
                            .foregroundStyle(BrandBook.Colors.secondaryText)
                    } else {
                        ForEach(characters) { character in
                            Button {
                                onCharacterSelected(character)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(character.name)
                                        .font(BrandBook.Typography.section(size: 20))
                                        .foregroundStyle(BrandBook.Colors.primaryText)
                                    Text(character.description)
                                        .font(BrandBook.Typography.caption())
                                        .foregroundStyle(BrandBook.Colors.secondaryText)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(BrandBook.Colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }                    
                case .error(let message):
                    Text(message)
                        .font(BrandBook.Typography.caption())
                        .foregroundStyle(BrandBook.Colors.error)
                }
            }
        }
        .padding()
        .navigationTitle(book.title)
        .foregroundStyle(BrandBook.Colors.primaryText)
        .background(BrandBook.Colors.background)
        .task {
            await viewModel.loadCharacters()
        }
    }
}

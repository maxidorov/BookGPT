import SwiftUI

struct CharactersListView: View {
    @StateObject private var viewModel: CharactersListViewModel
    private let book: Book
    let onCharacterSelected: (BookCharacter) -> Void

    init(
        book: Book,
        charactersRepository: CharactersRepository,
        onCharacterSelected: @escaping (BookCharacter) -> Void
    ) {
        self.book = book
        _viewModel = StateObject(
            wrappedValue: CharactersListViewModel(book: book, charactersRepository: charactersRepository)
        )
        self.onCharacterSelected = onCharacterSelected
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading characters...")
            case .loaded(let characters):
                if characters.isEmpty {
                    Text("No characters found")
                        .foregroundStyle(.secondary)
                } else {
                    List(characters) { character in
                        Button {
                            onCharacterSelected(character)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(character.name)
                                    .font(.headline)
                                Text(character.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            case .error(let message):
                Text(message)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle(book.title)
        .task {
            await viewModel.loadCharacters()
        }
    }
}

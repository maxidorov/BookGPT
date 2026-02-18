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
        ZStack {
            BrandBook.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    switch viewModel.state {
                    case .loading:
                        loadingContent
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
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(BrandBook.Colors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    case .error(let message):
                        VStack(alignment: .leading, spacing: 12) {
                            Text(message)
                                .font(BrandBook.Typography.caption())
                                .foregroundStyle(BrandBook.Colors.error)

                            Button {
                                Task {
                                    await viewModel.retry()
                                }
                            } label: {
                                Text("Retry")
                                    .font(BrandBook.Typography.body())
                                    .foregroundStyle(BrandBook.Colors.background)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(BrandBook.Colors.gold)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.large)
        .foregroundStyle(BrandBook.Colors.primaryText)
        .task {
            await viewModel.loadCharacters()
        }
    }

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(BrandBook.Colors.gold)
                Text("Loading characters...")
                    .font(BrandBook.Typography.body())
                    .foregroundStyle(BrandBook.Colors.primaryText)
            }
            .padding(.top, 8)

            ForEach(0..<6, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(BrandBook.Colors.surface)
                        .frame(width: 200, height: 20)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(BrandBook.Colors.surfaceMuted)
                        .frame(height: 36)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(BrandBook.Colors.surface.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

import SwiftUI

struct SearchResultsView: View {
    @StateObject private var viewModel: SearchResultsViewModel
    private let query: String
    let onBookSelected: (Book) -> Void

    init(
        query: String,
        booksRepository: BooksRepository,
        historyStore: BookHistoryStore,
        onBookSelected: @escaping (Book) -> Void
    ) {
        self.query = query
        _viewModel = StateObject(
            wrappedValue: SearchResultsViewModel(
                query: query,
                booksRepository: booksRepository,
                historyStore: historyStore
            )
        )
        self.onBookSelected = onBookSelected
    }

    var body: some View {
        ZStack {
            BrandBook.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    switch viewModel.state {
                    case .loading:
                        ProgressView("Searching...")
                            .tint(BrandBook.Colors.gold)
                            .font(BrandBook.Typography.body())
                            .padding(.top, 24)
                    case .loaded(let books):
                        if books.isEmpty {
                            Text("No books found")
                                .font(BrandBook.Typography.caption())
                                .foregroundStyle(BrandBook.Colors.secondaryText)
                        } else {
                            ForEach(books) { book in
                                Button {
                                    viewModel.selectBook(book)
                                    onBookSelected(book)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(book.title)
                                            .font(BrandBook.Typography.body())
                                            .foregroundStyle(BrandBook.Colors.primaryText)
                                        Text(book.author)
                                            .font(BrandBook.Typography.caption())
                                            .foregroundStyle(BrandBook.Colors.secondaryText)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(BrandBook.Colors.surfaceMuted)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(query)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

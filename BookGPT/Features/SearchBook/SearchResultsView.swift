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
                        loadingContent
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

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(BrandBook.Colors.gold)
                Text("Searching...")
                    .font(BrandBook.Typography.body())
                    .foregroundStyle(BrandBook.Colors.primaryText)
            }
            .padding(.top, 8)

            ForEach(0..<5, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(BrandBook.Colors.surface)
                        .frame(width: 220, height: 18)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(BrandBook.Colors.surfaceMuted)
                        .frame(width: 170, height: 14)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(BrandBook.Colors.surfaceMuted.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

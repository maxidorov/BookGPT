import SwiftUI

struct SearchBookView: View {
    @StateObject private var viewModel: SearchBookViewModel
    let onBookSelected: (Book) -> Void

    init(
        booksRepository: BooksRepository,
        historyStore: BookHistoryStore,
        onBookSelected: @escaping (Book) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: SearchBookViewModel(
                booksRepository: booksRepository,
                historyStore: historyStore
            )
        )
        self.onBookSelected = onBookSelected
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Midnight Library")
                        .font(BrandBook.Typography.title())
                        .foregroundStyle(BrandBook.Colors.paper)
                    Text("Find a book and speak with the characters inside it.")
                        .font(BrandBook.Typography.caption())
                        .foregroundStyle(BrandBook.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Enter book title", text: $viewModel.query)
                    .font(BrandBook.Typography.body())
                    .padding(12)
                    .background(BrandBook.Colors.surface)
                    .foregroundStyle(BrandBook.Colors.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button("Search") {
                    Task {
                        await viewModel.search()
                    }
                }
                .font(BrandBook.Typography.body())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(BrandBook.Colors.gold)
                .foregroundStyle(BrandBook.Colors.background)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                recentSection
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("BookGPT")
        .foregroundStyle(BrandBook.Colors.primaryText)
        .background(BrandBook.Colors.background)
        .task {
            viewModel.loadRecentBooks()
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        if !viewModel.recentBooks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent")
                    .font(BrandBook.Typography.section(size: 18))
                    .foregroundStyle(BrandBook.Colors.paper)

                ForEach(viewModel.recentBooks) { book in
                    Button {
                        viewModel.selectBook(book)
                        onBookSelected(book)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title)
                                    .font(BrandBook.Typography.body())
                                    .foregroundStyle(BrandBook.Colors.primaryText)
                                Text(book.author)
                                    .font(BrandBook.Typography.caption())
                                    .foregroundStyle(BrandBook.Colors.secondaryText)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(BrandBook.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Text("Search a book to start")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)
        case .loading:
            ProgressView("Searching...")
                .tint(BrandBook.Colors.gold)
        case .loaded(let books):
            if books.isEmpty {
                Text("No books found")
                    .font(BrandBook.Typography.caption())
                    .foregroundStyle(BrandBook.Colors.secondaryText)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search Results")
                        .font(BrandBook.Typography.section(size: 18))
                        .foregroundStyle(BrandBook.Colors.paper)

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
            }
        case .error(let message):
            Text(message)
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.error)
        }
    }
}

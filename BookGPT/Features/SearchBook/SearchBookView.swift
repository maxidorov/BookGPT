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
        VStack(spacing: 16) {
            TextField("Enter book title", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)

            Button("Search") {
                Task {
                    await viewModel.search()
                }
            }
            .buttonStyle(.borderedProminent)

            recentSection

            content

            Spacer()
        }
        .padding()
        .navigationTitle("BookGPT")
        .task {
            viewModel.loadRecentBooks()
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        if !viewModel.recentBooks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent")
                    .font(.headline)

                ForEach(viewModel.recentBooks) { book in
                    Button {
                        viewModel.selectBook(book)
                        onBookSelected(book)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Text(book.author)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.bordered)
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
                .foregroundStyle(.secondary)
        case .loading:
            ProgressView("Searching...")
        case .loaded(let books):
            if books.isEmpty {
                Text("No books found")
                    .foregroundStyle(.secondary)
            } else {
                List(books) { book in
                    Button {
                        viewModel.selectBook(book)
                        onBookSelected(book)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                            Text(book.author)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
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
}

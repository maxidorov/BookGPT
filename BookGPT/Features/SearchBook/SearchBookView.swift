import SwiftUI

struct SearchBookView: View {
    @StateObject private var viewModel: SearchBookViewModel
    let onBookSelected: (Book) -> Void

    init(booksRepository: BooksRepository, onBookSelected: @escaping (Book) -> Void) {
        _viewModel = StateObject(wrappedValue: SearchBookViewModel(booksRepository: booksRepository))
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

            content

            Spacer()
        }
        .padding()
        .navigationTitle("BookGPT")
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

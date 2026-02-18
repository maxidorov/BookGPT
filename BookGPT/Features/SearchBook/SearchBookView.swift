import SwiftUI

struct SearchBookView: View {
    @StateObject private var viewModel: SearchBookViewModel
    @FocusState private var isSearchFocused: Bool
    let onSearchRequested: (String) -> Void
    let onBookSelected: (Book) -> Void

    init(
        historyStore: BookHistoryStore,
        onSearchRequested: @escaping (String) -> Void,
        onBookSelected: @escaping (Book) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: SearchBookViewModel(historyStore: historyStore)
        )
        self.onSearchRequested = onSearchRequested
        self.onBookSelected = onBookSelected
    }

    var body: some View {
        ZStack {
            BrandBook.Colors.background.ignoresSafeArea()

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
                        .focused($isSearchFocused)
                        .font(BrandBook.Typography.body())
                        .padding(12)
                        .background(BrandBook.Colors.surface)
                        .foregroundStyle(BrandBook.Colors.primaryText)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .submitLabel(.search)
                        .onSubmit {
                            searchTapped()
                        }

                    Button {
                        searchTapped()
                    } label: {
                        Text("Search")
                            .font(BrandBook.Typography.body())
                            .foregroundStyle(BrandBook.Colors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(BrandBook.Colors.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if let validationError = viewModel.validationError {
                        Text(validationError)
                            .font(BrandBook.Typography.caption())
                            .foregroundStyle(BrandBook.Colors.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    recentSection
                    Spacer(minLength: 120)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .foregroundStyle(BrandBook.Colors.primaryText)
        .task {
            viewModel.loadRecentBooks()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isSearchFocused = false
                }
            }
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
        EmptyView()
    }

    private func searchTapped() {
        isSearchFocused = false
        guard let query = viewModel.validatedQueryForSearch() else { return }
        onSearchRequested(query)
    }
}

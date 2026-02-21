import SwiftUI
import WebKit

struct SearchBookView: View {
    @StateObject private var viewModel: SearchBookViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var isShowingSettings = false
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
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isSearchFocused = false
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
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

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var activeDocument: SettingsLegalDocument?

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBook.Colors.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Legal")
                        .font(BrandBook.Typography.section(size: 22))
                        .foregroundStyle(BrandBook.Colors.paper)

                    if let termsURL = AppConfig.termsOfUseURL {
                        legalButton(title: "Terms of Use") {
                            activeDocument = SettingsLegalDocument(title: "Terms of Use", url: termsURL)
                        }
                    }

                    if let privacyURL = AppConfig.privacyPolicyURL {
                        legalButton(title: "Privacy Policy") {
                            activeDocument = SettingsLegalDocument(title: "Privacy Policy", url: privacyURL)
                        }
                    }

                    Spacer()
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $activeDocument) { document in
            NavigationStack {
                SettingsInAppWebView(url: document.url)
                    .navigationTitle(document.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Close") {
                                activeDocument = nil
                            }
                        }
                    }
            }
        }
    }

    private func legalButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(BrandBook.Typography.body())
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(BrandBook.Colors.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(BrandBook.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsLegalDocument: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
}

private struct SettingsInAppWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView(frame: .zero)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}

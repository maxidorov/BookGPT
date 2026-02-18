import SwiftUI
import ChatKit
import UIKit

struct CharacterChatView: View {
    private let chatService: CharacterChatService
    private let book: Book
    private let character: BookCharacter

    init(chatService: CharacterChatService, book: Book, character: BookCharacter) {
        self.chatService = chatService
        self.book = book
        self.character = character
    }

    var body: some View {
        CharacterChatContainerView(chatService: chatService, book: book, character: character)
            .navigationTitle(character.name)
            .navigationBarTitleDisplayMode(.inline)
            .background(BrandBook.Colors.background.ignoresSafeArea())
    }
}

private struct CharacterChatContainerView: UIViewControllerRepresentable {
    private static let minimumVisualBottomInset: CGFloat = 68

    let chatService: CharacterChatService
    let book: Book
    let character: BookCharacter

    func makeCoordinator() -> Coordinator {
        Coordinator(chatService: chatService, book: book, character: character)
    }

    func makeUIViewController(context: Context) -> MessageListViewController {
        let dataProvider = EmptyChatDataProvider()
        let viewModel = ChatViewModel(
            currentUserID: Coordinator.currentUser.id,
            isGroupChat: false,
            dataProvider: dataProvider
        )

        let controller = MessageListViewController(viewModel: viewModel, theme: makeBrandTheme())
        controller.loadViewIfNeeded()
        Self.applyMinimumBottomInsetIfNeeded(to: controller)
        controller.onOutgoingMessageSent = { [weak controller, weak viewModel, coordinator = context.coordinator] outgoingMessage in
            guard let viewModel else { return }
            controller?.scrollToLatestMessages(animated: true)
            coordinator.handleOutgoingMessage(outgoingMessage, chatViewModel: viewModel) {
                controller?.scrollToLatestMessages(animated: true)
            }
        }
        return controller
    }

    private func makeBrandTheme() -> ChatTheme {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return ChatTheme(
            backgroundColor: BrandBook.Colors.uiBackground,
            outgoingBubble: .init(
                backgroundColor: BrandBook.Colors.uiGold,
                textColor: BrandBook.Colors.uiBackground,
                cornerRadius: 16,
                contentInsets: .init(top: 10, left: 12, bottom: 10, right: 12),
                maxWidthRatio: 0.75
            ),
            incomingBubble: .init(
                backgroundColor: BrandBook.Colors.uiSurfaceMuted,
                textColor: BrandBook.Colors.uiPaper,
                cornerRadius: 16,
                contentInsets: .init(top: 10, left: 12, bottom: 10, right: 12),
                maxWidthRatio: 0.8
            ),
            avatar: .init(
                isVisible: false,
                size: 32,
                cornerRadius: 16,
                placeholderBackgroundColor: BrandBook.Colors.uiSurface
            ),
            dateSeparator: .init(
                textColor: BrandBook.Colors.uiPaper,
                backgroundColor: BrandBook.Colors.uiSurface,
                font: BrandBook.Typography.uiCaption(),
                contentInsets: .init(top: 4, left: 10, bottom: 4, right: 10),
                cornerRadius: 10,
                formatter: formatter
            ),
            typingIndicator: .init(
                textColor: BrandBook.Colors.uiPaper,
                backgroundColor: BrandBook.Colors.uiSurface,
                font: BrandBook.Typography.uiBody(),
                contentInsets: .init(top: 8, left: 12, bottom: 8, right: 12),
                cornerRadius: 16
            ),
            header: .init(
                height: 44,
                backgroundColor: BrandBook.Colors.uiBackground,
                titleFont: BrandBook.Typography.uiTitle(),
                titleColor: BrandBook.Colors.uiPaper
            )
        )
    }

    func updateUIViewController(_ uiViewController: MessageListViewController, context: Context) {
        Self.applyMinimumBottomInsetIfNeeded(to: uiViewController)
    }

    private static func applyMinimumBottomInsetIfNeeded(to controller: MessageListViewController) {
        let currentInset = controller.collectionView.contentInset.top
        let targetInset = max(currentInset, minimumVisualBottomInset)
        guard targetInset != currentInset else { return }

        controller.collectionView.contentInset.top = targetInset
        controller.collectionView.scrollIndicatorInsets.top = targetInset
        controller.scrollToLatestMessages(animated: false)
    }

    final class Coordinator {
        static let currentUser = ChatUser(id: "user_me", displayName: "You")

        private let chatService: CharacterChatService
        private let book: Book
        private let character: BookCharacter
        private let assistantUser: ChatUser
        private var domainHistory: [ChatMessage] = []

        init(chatService: CharacterChatService, book: Book, character: BookCharacter) {
            self.chatService = chatService
            self.book = book
            self.character = character
            self.assistantUser = ChatUser(id: "assistant_character", displayName: character.name)
        }

        func handleOutgoingMessage(
            _ message: Message,
            chatViewModel: ChatViewModel,
            scrollToLatest: @escaping () -> Void
        ) {
            guard case let .text(userText) = message.content else {
                return
            }

            domainHistory.append(ChatMessage(role: .user, text: userText, createdAt: message.createdAt))

            Task {
                do {
                    let response = try await chatService.sendMessage(
                        userText: userText,
                        history: domainHistory,
                        character: character,
                        book: book
                    )

                    domainHistory.append(response)

                    let assistantMessage = Message(
                        id: UUID().uuidString,
                        sender: assistantUser,
                        content: .text(response.text),
                        createdAt: Date(),
                        status: .sent
                    )

                    await MainActor.run {
                        chatViewModel.insert(message: assistantMessage)
                        scrollToLatest()
                    }
                } catch {
                    let failedMessage = Message(
                        id: UUID().uuidString,
                        sender: assistantUser,
                        content: .text("Could not generate reply. Please check API key or try again."),
                        createdAt: Date(),
                        status: .failed(reason: error.localizedDescription)
                    )

                    await MainActor.run {
                        chatViewModel.insert(message: failedMessage)
                        scrollToLatest()
                    }
                }
            }
        }
    }
}

private struct EmptyChatDataProvider: ChatDataProvider {
    func fetchInitialMessages() async throws -> ChatHistoryPage {
        ChatHistoryPage(messages: [], hasMoreHistory: false)
    }

    func fetchOlderMessages(before oldestLoadedMessage: Message?) async throws -> ChatHistoryPage {
        ChatHistoryPage(messages: [], hasMoreHistory: false)
    }
}

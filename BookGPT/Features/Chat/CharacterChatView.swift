import SwiftUI
import ChatKit

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

        let controller = MessageListViewController(viewModel: viewModel)
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

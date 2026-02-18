import Foundation
import LLMKit
import os

struct LLMCharacterChatService: CharacterChatService {
    enum ServiceError: LocalizedError {
        case missingAPIKey
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "OpenRouter API key is missing. Set AppConfig.openRouterAPIKey."
            case .emptyResponse:
                return "Model returned an empty response."
            }
        }
    }

    private let logger = Logger(subsystem: "com.ms.BookGPT", category: "LLMCharacterChatService")
    private let client: LLMClientProtocol

    init(client: LLMClientProtocol) {
        self.client = client
    }

    func sendMessage(
        userText: String,
        history: [ChatMessage],
        character: BookCharacter,
        book: Book
    ) async throws -> ChatMessage {
        logger.debug(
            "sendMessage userTextLength=\(userText.count) historyCount=\(history.count) character=\(character.name, privacy: .public)"
        )

        guard !client.configuration.apiKey.isEmpty else {
            logger.error("sendMessage failed: missing API key")
            throw ServiceError.missingAPIKey
        }

        let llmMessages = history.map { message in
            LLMMessage(
                role: message.role == .user ? .user : .assistant,
                content: [.text(message.text)]
            )
        }

        var updatedConfiguration = client.configuration
        updatedConfiguration.systemPrompt = Self.systemPrompt(character: character, book: book)
        client.update(configuration: updatedConfiguration)

        let response = try await client.send(messages: llmMessages)
        logger.debug(
            "response model=\(response.model, privacy: .public) latencyMs=\(response.latencyMs) tokens=\(response.usage.totalTokens) textLength=\(response.text.count)"
        )

        let trimmed = response.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            logger.error("response text is empty; raw=\"\(response.text, privacy: .public)\"")
            throw ServiceError.emptyResponse
        }

        return ChatMessage(role: .assistant, text: trimmed)
    }

    private static func systemPrompt(character: BookCharacter, book: Book) -> String {
        [
            "You are roleplaying as \(character.name) from \(book.title) by \(book.author).",
            "Stay in character, keep the tone and worldview of this character.",
            "Never say you are an AI assistant.",
            "If the user asks outside the canon, answer as \(character.name) would, but mark assumptions briefly.",
            "Keep answers concise and conversational."
        ].joined(separator: " ")
    }
}

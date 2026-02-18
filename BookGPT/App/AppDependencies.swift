import Foundation
import LLMKit

struct AppDependencies {
    let booksRepository: BooksRepository
    let charactersRepository: CharactersRepository
    let chatService: CharacterChatService

    static let live = AppDependencies(
        booksRepository: LLMBooksRepository(
            client: LLMClient(
                configuration: LLMConfiguration(
                    apiKey: AppConfig.openRouterAPIKey,
                    model: AppConfig.model,
                    systemPrompt: nil,
                    temperature: 0.2,
                    maxTokens: 700,
                    imagePolicy: .none
                ),
                delegate: LLMConsoleLogger.shared
            )
        ),
        charactersRepository: LLMCharactersRepository(
            client: LLMClient(
                configuration: LLMConfiguration(
                    apiKey: AppConfig.openRouterAPIKey,
                    model: AppConfig.model,
                    systemPrompt: nil,
                    temperature: 0.2,
                    maxTokens: 800,
                    imagePolicy: .none
                ),
                delegate: LLMConsoleLogger.shared
            )
        ),
        chatService: LLMCharacterChatService(
            client: LLMClient(
                configuration: LLMConfiguration(
                    apiKey: AppConfig.openRouterAPIKey,
                    model: AppConfig.model,
                    systemPrompt: nil,
                    temperature: 0.7,
                    maxTokens: 800,
                    imagePolicy: .none
                ),
                delegate: LLMConsoleLogger.shared
            )
        )
    )
}

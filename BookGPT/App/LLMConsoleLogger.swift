import Foundation
import LLMKit

final class LLMConsoleLogger: LLMEventDelegate {
    static let shared = LLMConsoleLogger()

    private init() {}

    func llmClient(
        _ client: any LLMClientProtocol,
        willSendMessages messages: [LLMMessage],
        configuration: LLMConfiguration
    ) {
        print("----- LLM REQUEST START -----")
        print("model: \(configuration.model)")
        print("temperature: \(configuration.temperature)")
        print("maxTokens: \(configuration.maxTokens)")
        print("systemPrompt: \(configuration.systemPrompt ?? "<nil>")")

        for (index, message) in messages.enumerated() {
            print("message[\(index)] role=\(message.role.rawValue)")
            for (contentIndex, content) in message.content.enumerated() {
                switch content {
                case .text(let text):
                    print("message[\(index)].content[\(contentIndex)].text=\(text)")
                case .image:
                    print("message[\(index)].content[\(contentIndex)].image=<binary image>")
                }
            }
        }
        print("----- LLM REQUEST END -----")
    }

    func llmClient(
        _ client: any LLMClientProtocol,
        didReceiveResponse response: LLMResponse
    ) {
        print("----- LLM RESPONSE START -----")
        print("model: \(response.model)")
        print("latencyMs: \(response.latencyMs)")
        print("promptTokens: \(response.usage.promptTokens)")
        print("completionTokens: \(response.usage.completionTokens)")
        print("totalTokens: \(response.usage.totalTokens)")
        print("text: \(response.text)")
        print("----- LLM RESPONSE END -----")
    }

    func llmClient(
        _ client: any LLMClientProtocol,
        didFailWithError error: LLMError
    ) {
        print("----- LLM ERROR -----")
        print("error: \(error)")
        print("---------------------")
    }
}

import Foundation
import LLMKit
import os

struct LLMCharactersRepository: CharactersRepository {
    private struct CharactersPayload: Decodable {
        struct Item: Decodable {
            let name: String
            let description: String
        }

        let characters: [Item]

        enum CodingKeys: String, CodingKey {
            case characters
            case items
            case results
        }

        init(from decoder: Decoder) throws {
            if let array = try? [Item](from: decoder) {
                characters = array
                return
            }

            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let characters = try? container.decode([Item].self, forKey: .characters) {
                self.characters = characters
                return
            }
            if let items = try? container.decode([Item].self, forKey: .items) {
                self.characters = items
                return
            }
            if let results = try? container.decode([Item].self, forKey: .results) {
                self.characters = results
                return
            }
            self.characters = []
        }
    }

    private let logger = Logger(subsystem: "com.ms.BookGPT", category: "LLMCharactersRepository")
    private let client: LLMClientProtocol

    init(client: LLMClientProtocol) {
        self.client = client
    }

    func characters(for book: Book) async throws -> [BookCharacter] {
        logger.debug("characters book=\(book.title, privacy: .public) author=\(book.author, privacy: .public)")

        var configuration = client.configuration
        configuration.systemPrompt = """
        Return valid JSON only.
        Given a book, return notable characters from that exact book.
        Output format:
        {"characters":[{"name":"<character name>","description":"<short personality summary>"}]}
        Do not use placeholder values like "string", "name", "description".
        No markdown, no explanations.
        """
        client.update(configuration: configuration)

        let prompt = """
        Book title: \(book.title)
        Author: \(book.author)
        Return up to 20 characters.
        """

        let response = try await client.send(messages: [LLMMessage(role: .user, content: [.text(prompt)])])
        logger.debug(
            "characters response model=\(response.model, privacy: .public) tokens=\(response.usage.totalTokens) textLength=\(response.text.count)"
        )

        let payload: CharactersPayload
        do {
            payload = try LLMStructuredOutputParser.decode(CharactersPayload.self, from: response.text)
        } catch {
            logger.error("characters first decode failed: \(error.localizedDescription, privacy: .public)")
            logger.debug("characters raw head=\(String(response.text.prefix(400)), privacy: .public)")
            let normalized = try await normalizeCharactersJSON(from: response.text)
            payload = try LLMStructuredOutputParser.decode(CharactersPayload.self, from: normalized)
        }

        let filteredCharacters = payload.characters
            .map {
                BookCharacter(
                    name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: $0.description.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !Self.isPlaceholder($0.name) && !Self.isPlaceholder($0.description) }

        logger.debug("characters parsedCount=\(filteredCharacters.count)")
        for character in filteredCharacters.prefix(10) {
            logger.debug("character name=\(character.name, privacy: .public) description=\(character.description, privacy: .public)")
        }

        return filteredCharacters
    }

    private func normalizeCharactersJSON(from rawText: String) async throws -> String {
        var configuration = client.configuration
        configuration.systemPrompt = """
        Convert input into valid JSON only.
        Required output:
        {"characters":[{"name":"<character name>","description":"<short personality summary>"}]}
        Do not use placeholder values like "string", "name", "description".
        Do not add markdown.
        """
        configuration.temperature = 0
        client.update(configuration: configuration)

        let normalizationPrompt = """
        Normalize the following content into the required JSON structure.

        INPUT:
        \(rawText)
        """

        let response = try await client.send(messages: [
            LLMMessage(role: .user, content: [.text(normalizationPrompt)])
        ])

        logger.debug("characters normalization textLength=\(response.text.count)")
        return response.text
    }

    private static func isPlaceholder(_ value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let placeholders: Set<String> = [
            "string",
            "name",
            "description",
            "<character name>",
            "<short personality summary>",
            "\"string\""
        ]
        return normalized.isEmpty || placeholders.contains(normalized)
    }
}

import Foundation
import LLMKit
import os

struct LLMBooksRepository: BooksRepository {
    private struct BooksPayload: Decodable {
        struct Item: Decodable {
            let title: String
            let author: String
        }

        let books: [Item]

        enum CodingKeys: String, CodingKey {
            case books
            case items
            case results
        }

        init(from decoder: Decoder) throws {
            if let array = try? [Item](from: decoder) {
                books = array
                return
            }

            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let books = try? container.decode([Item].self, forKey: .books) {
                self.books = books
                return
            }
            if let items = try? container.decode([Item].self, forKey: .items) {
                self.books = items
                return
            }
            if let results = try? container.decode([Item].self, forKey: .results) {
                self.books = results
                return
            }
            self.books = []
        }
    }

    private let logger = Logger(subsystem: "com.ms.BookGPT", category: "LLMBooksRepository")
    private let client: LLMClientProtocol

    init(client: LLMClientProtocol) {
        self.client = client
    }

    func searchBooks(query: String) async throws -> [Book] {
        logger.debug("searchBooks query=\(query, privacy: .public)")

        var configuration = client.configuration
        configuration.systemPrompt = """
        Return valid JSON only.
        Find real books by user query.
        Output format:
        {"books":[{"title":"<book title>","author":"<author name>"}]}
        Do not use placeholder values like "string", "title", "author", "<book title>".
        No markdown, no explanations.
        """
        client.update(configuration: configuration)

        let messages = [
            LLMMessage(
                role: .user,
                content: [.text("Find books matching: \(query). Return up to 12 books.")]
            )
        ]

        let response = try await client.send(messages: messages)
        logger.debug(
            "searchBooks response model=\(response.model, privacy: .public) tokens=\(response.usage.totalTokens) textLength=\(response.text.count)"
        )

        let payload: BooksPayload
        do {
            payload = try LLMStructuredOutputParser.decode(BooksPayload.self, from: response.text)
        } catch {
            logger.error("searchBooks first decode failed: \(error.localizedDescription, privacy: .public)")
            logger.debug("searchBooks raw head=\(String(response.text.prefix(400)), privacy: .public)")
            let normalized = try await normalizeBooksJSON(from: response.text)
            payload = try LLMStructuredOutputParser.decode(BooksPayload.self, from: normalized)
        }

        let filteredBooks = payload.books
            .map { Book(title: $0.title.trimmingCharacters(in: .whitespacesAndNewlines), author: $0.author.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !Self.isPlaceholder($0.title) && !Self.isPlaceholder($0.author) }

        logger.debug("searchBooks parsedCount=\(filteredBooks.count)")
        for book in filteredBooks.prefix(10) {
            logger.debug("book title=\(book.title, privacy: .public) author=\(book.author, privacy: .public)")
        }

        return filteredBooks
    }

    private func normalizeBooksJSON(from rawText: String) async throws -> String {
        var configuration = client.configuration
        configuration.systemPrompt = """
        Convert input into valid JSON only.
        Required output:
        {"books":[{"title":"<book title>","author":"<author name>"}]}
        Do not use placeholder values like "string", "title", "author", "<book title>".
        Do not add markdown.
        """
        configuration.temperature = 0
        client.update(configuration: configuration)

        let normalizationPrompt = """
        Normalize the following content into the required JSON structure.
        Keep only real book title and author pairs.

        INPUT:
        \(rawText)
        """

        let response = try await client.send(messages: [
            LLMMessage(role: .user, content: [.text(normalizationPrompt)])
        ])

        logger.debug("searchBooks normalization textLength=\(response.text.count)")
        return response.text
    }

    private static func isPlaceholder(_ value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let placeholders: Set<String> = [
            "string",
            "title",
            "author",
            "<book title>",
            "<author name>",
            "\"string\""
        ]
        return normalized.isEmpty || placeholders.contains(normalized)
    }
}

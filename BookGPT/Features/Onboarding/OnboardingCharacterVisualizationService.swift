import Foundation

struct OnboardingCharacterVisualization: Equatable {
    let characterName: String
    let imageURL: URL
}

protocol OnboardingCharacterVisualizing {
    func generateCharacterVisualization(for bookTitle: String) async throws -> OnboardingCharacterVisualization
}

enum OnboardingCharacterVisualizationError: Error {
    case noCharacterFound
    case noImageFound
}

struct WikipediaCharacterVisualizationService: OnboardingCharacterVisualizing {
    private struct SearchResponse: Decodable {
        struct Query: Decodable {
            struct SearchItem: Decodable {
                let title: String
            }

            let search: [SearchItem]
        }

        let query: Query
    }

    private struct SummaryResponse: Decodable {
        struct Thumbnail: Decodable {
            let source: String
        }

        let title: String
        let thumbnail: Thumbnail?
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generateCharacterVisualization(for bookTitle: String) async throws -> OnboardingCharacterVisualization {
        let normalizedBook = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBook.isEmpty else {
            throw OnboardingCharacterVisualizationError.noCharacterFound
        }

        if let curatedCharacter = Self.curatedCharacter(for: normalizedBook),
           let visualization = try await fetchVisualizationForCharacter(named: curatedCharacter) {
            return visualization
        }

        let searchQueries = [
            "\(normalizedBook) main character",
            "\(normalizedBook) character",
            "\(normalizedBook) protagonist"
        ]

        for query in searchQueries {
            let titles = try await searchTitles(for: query, limit: 8)
            for title in titles {
                if let visualization = try await fetchVisualizationForCharacter(named: title) {
                    return visualization
                }
            }
        }

        throw OnboardingCharacterVisualizationError.noImageFound
    }

    private func fetchVisualizationForCharacter(named characterName: String) async throws -> OnboardingCharacterVisualization? {
        guard let encodedTitle = characterName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encodedTitle)") else {
            return nil
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            return nil
        }

        let summary = try JSONDecoder().decode(SummaryResponse.self, from: data)
        guard let source = summary.thumbnail?.source, let imageURL = URL(string: source) else {
            return nil
        }

        return OnboardingCharacterVisualization(characterName: summary.title, imageURL: imageURL)
    }

    private func searchTitles(for query: String, limit: Int) async throws -> [String] {
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "search"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "utf8", value: "1"),
            URLQueryItem(name: "srlimit", value: "\(limit)"),
            URLQueryItem(name: "srsearch", value: query)
        ]

        guard let url = components?.url else {
            return []
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            return []
        }

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.query.search.map(\.title)
    }

    private static func curatedCharacter(for bookTitle: String) -> String? {
        let key = bookTitle.lowercased()
        for (pattern, character) in curatedMap {
            if key.contains(pattern) {
                return character
            }
        }
        return nil
    }

    private static let curatedMap: [(String, String)] = [
        ("sherlock holmes", "Sherlock Holmes"),
        ("pride and prejudice", "Elizabeth Bennet"),
        ("great gatsby", "Jay Gatsby"),
        ("1984", "Winston Smith"),
        ("crime and punishment", "Rodion Raskolnikov"),
        ("to kill a mockingbird", "Atticus Finch"),
        ("lord of the rings", "Frodo Baggins"),
        ("the hobbit", "Bilbo Baggins"),
        ("dune", "Paul Atreides")
    ]
}

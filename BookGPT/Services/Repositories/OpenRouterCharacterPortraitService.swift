import Foundation

struct OpenRouterCharacterPortraitService: CharacterPortraitGenerating {
    private struct RequestBody: Encodable {
        struct RequestMessage: Encodable {
            let role: String
            let content: String
        }

        struct ImageConfig: Encodable {
            let size: String
            let aspect_ratio: String
            let image_size: String
        }

        let model: String
        let messages: [RequestMessage]
        let modalities: [String]
        let stream: Bool
        let size: String
        let image_config: ImageConfig
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generatePortrait(for character: BookCharacter, in book: Book) async throws -> Data {
        guard !AppConfig.openRouterAPIKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        guard let endpointURL = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AppConfig.openRouterAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("https://bookgpt.local", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("BookGPT", forHTTPHeaderField: "X-Title")

        let prompt = """
        Create an original cinematic portrait of \(character.name), inspired by \(book.title) by \(book.author).
        Character notes: \(character.description).
        Important: create an original image, no logos, no text, no direct copy of any existing illustration.
        """

        let payload = RequestBody(
            model: AppConfig.imageModel,
            messages: [.init(role: "user", content: prompt)],
            modalities: ["image"],
            stream: false,
            size: "1024x1024",
            image_config: .init(size: "1024x1024", aspect_ratio: "1:1", image_size: "1K")
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        guard let imageData = try await extractImageData(from: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        return imageData
    }

    private func extractImageData(from responseData: Data) async throws -> Data? {
        guard
            let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let firstChoice = choices.first,
            let message = firstChoice["message"] as? [String: Any],
            let images = message["images"] as? [[String: Any]],
            let firstImage = images.first
        else {
            return nil
        }

        if
            let imageURLDict = firstImage["image_url"] as? [String: Any],
            let urlString = imageURLDict["url"] as? String
        {
            return try await decodeImagePayload(from: urlString)
        }

        if let urlString = firstImage["url"] as? String {
            return try await decodeImagePayload(from: urlString)
        }

        return nil
    }

    private func decodeImagePayload(from payload: String) async throws -> Data? {
        if payload.hasPrefix("data:image/"), let encodedPart = payload.split(separator: ",").last {
            return Data(base64Encoded: String(encodedPart))
        }
        guard let url = URL(string: payload) else { return nil }
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            return nil
        }
        return data
    }
}

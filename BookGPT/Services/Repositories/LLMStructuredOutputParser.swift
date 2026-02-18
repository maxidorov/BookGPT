import Foundation

enum LLMStructuredOutputParser {
    static func decode<T: Decodable>(_ type: T.Type, from rawText: String) throws -> T {
        let jsonText = extractJSONArrayOrObject(from: rawText)
        let data = Data(jsonText.utf8)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func extractJSONArrayOrObject(from rawText: String) -> String {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutFence = stripCodeFence(from: trimmed)

        if let object = extractBalancedChunk(from: withoutFence, open: "{", close: "}") {
            return object
        }

        if let array = extractBalancedChunk(from: withoutFence, open: "[", close: "]") {
            return array
        }

        return withoutFence
    }

    private static func stripCodeFence(from text: String) -> String {
        guard text.hasPrefix("```") else { return text }

        let lines = text.components(separatedBy: .newlines)
        guard lines.count >= 3 else { return text }

        var mutableLines = lines
        if mutableLines.first?.hasPrefix("```") == true {
            mutableLines.removeFirst()
        }
        if mutableLines.last?.trimmingCharacters(in: .whitespacesAndNewlines) == "```" {
            mutableLines.removeLast()
        }

        return mutableLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractBalancedChunk(from text: String, open: Character, close: Character) -> String? {
        guard let start = text.firstIndex(of: open) else { return nil }
        var depth = 0
        var end: String.Index?

        for index in text.indices where index >= start {
            let char = text[index]
            if char == open { depth += 1 }
            if char == close {
                depth -= 1
                if depth == 0 {
                    end = index
                    break
                }
            }
        }

        guard let end else { return nil }
        return String(text[start...end])
    }
}

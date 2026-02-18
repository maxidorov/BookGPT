import Foundation

enum AppRoute: Hashable {
    case searchResults(query: String)
    case characters(book: Book)
    case chat(book: Book, character: BookCharacter)
}

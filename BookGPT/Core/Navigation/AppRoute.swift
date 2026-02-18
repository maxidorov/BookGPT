import Foundation

enum AppRoute: Hashable {
    case characters(book: Book)
    case chat(book: Book, character: BookCharacter)
}

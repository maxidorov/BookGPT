import SwiftUI
import UIKit

enum BrandBook {
    enum Colors {
        static let background = Color(red: 11 / 255, green: 11 / 255, blue: 11 / 255)
        static let surface = Color(red: 24 / 255, green: 24 / 255, blue: 24 / 255)
        static let surfaceMuted = Color(red: 36 / 255, green: 36 / 255, blue: 36 / 255)
        static let paper = Color(red: 216 / 255, green: 200 / 255, blue: 168 / 255)
        static let gold = Color(red: 205 / 255, green: 126 / 255, blue: 52 / 255)
        static let primaryText = paper
        static let secondaryText = Color(red: 190 / 255, green: 175 / 255, blue: 145 / 255)
        static let error = Color(red: 225 / 255, green: 105 / 255, blue: 105 / 255)

        static let uiBackground = UIColor(red: 11 / 255, green: 11 / 255, blue: 11 / 255, alpha: 1)
        static let uiSurface = UIColor(red: 24 / 255, green: 24 / 255, blue: 24 / 255, alpha: 1)
        static let uiSurfaceMuted = UIColor(red: 36 / 255, green: 36 / 255, blue: 36 / 255, alpha: 1)
        static let uiPaper = UIColor(red: 216 / 255, green: 200 / 255, blue: 168 / 255, alpha: 1)
        static let uiGold = UIColor(red: 205 / 255, green: 126 / 255, blue: 52 / 255, alpha: 1)
    }

    enum Typography {
        static func title(size: CGFloat = 28) -> Font {
            .custom("Georgia-Bold", size: size)
        }

        static func section(size: CGFloat = 20) -> Font {
            .custom("Georgia-Bold", size: size)
        }

        static func body(size: CGFloat = 17) -> Font {
            .custom("Georgia", size: size)
        }

        static func caption(size: CGFloat = 16) -> Font {
            .custom("Georgia-Italic", size: size)
        }

        static func uiBody(size: CGFloat = 16) -> UIFont {
            UIFont(name: "Georgia", size: size) ?? .systemFont(ofSize: size)
        }

        static func uiTitle(size: CGFloat = 17) -> UIFont {
            UIFont(name: "Georgia-Bold", size: size) ?? .boldSystemFont(ofSize: size)
        }

        static func uiCaption(size: CGFloat = 15) -> UIFont {
            UIFont(name: "Georgia-Italic", size: size) ?? .italicSystemFont(ofSize: size)
        }
    }
}

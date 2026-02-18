import SwiftUI
import UIKit

@main
struct BookGPTApp: App {
    init() {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: BrandBook.Colors.uiPaper,
            .font: BrandBook.Typography.uiTitle(size: 19)
        ]
        let largeTitleAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: BrandBook.Colors.uiPaper,
            .font: BrandBook.Typography.uiTitle(size: 34)
        ]

        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithOpaqueBackground()
        standardAppearance.backgroundColor = BrandBook.Colors.uiBackground
        standardAppearance.shadowColor = .clear
        standardAppearance.titleTextAttributes = titleAttributes
        standardAppearance.largeTitleTextAttributes = largeTitleAttributes

        let largeTitleAppearance = UINavigationBarAppearance()
        largeTitleAppearance.configureWithTransparentBackground()
        largeTitleAppearance.backgroundColor = .clear
        largeTitleAppearance.shadowColor = .clear
        largeTitleAppearance.titleTextAttributes = titleAttributes
        largeTitleAppearance.largeTitleTextAttributes = largeTitleAttributes

        let navigationBar = UINavigationBar.appearance()
        navigationBar.prefersLargeTitles = true
        navigationBar.tintColor = BrandBook.Colors.uiGold
        navigationBar.standardAppearance = standardAppearance
        navigationBar.compactAppearance = standardAppearance
        navigationBar.scrollEdgeAppearance = largeTitleAppearance

        UITextField.appearance().tintColor = BrandBook.Colors.uiGold
        UITextView.appearance().tintColor = BrandBook.Colors.uiGold
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(BrandBook.Colors.gold)
        }
    }
}

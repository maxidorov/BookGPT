import Foundation

enum AppConfig {
    static let openRouterAPIKey: String = "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"
    static let model: String = "anthropic/claude-sonnet-4.6"
    static let imageModel: String = "openai/gpt-5-image"

    static let revenueCatAPIKey: String = "appl_GGxEIiuFUpSxZFberulvwzCAYZM"
    static let revenueCatOfferingID: String = "standard"
    static let revenueCatWeeklyProductID: String = "book_gpt_pro_weekly"
    static let revenueCatAnnualProductID: String = "book_gpt_pro_annual"

    static let termsOfUseURL: URL? = URL(string: "https://example.com/terms")
    static let privacyPolicyURL: URL? = URL(string: "https://example.com/privacy")
}

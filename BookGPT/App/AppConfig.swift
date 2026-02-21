import Foundation

enum AppConfig {
    static let openRouterAPIKey: String = "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"
    static let model: String = "anthropic/claude-sonnet-4.6"
    static let imageModel: String = "openai/gpt-5-image"

    static let revenueCatAPIKey: String = "appl_GGxEIiuFUpSxZFberulvwzCAYZM"
    static let revenueCatOfferingID: String = "standard"
    static let revenueCatWeeklyProductID: String = "book_gpt_pro_weekly"
    static let revenueCatAnnualProductID: String = "book_gpt_pro_annual"

    static let termsOfUseURL: URL? = URL(string: "https://cool-mall-f57.notion.site/Terms-of-Use-30efd7ddf43180418ddce5747bdff1cc")
    static let privacyPolicyURL: URL? = URL(string: "https://cool-mall-f57.notion.site/Privacy-Policy-30efd7ddf4318004a362de2eb9a07ca9?t=new")
}

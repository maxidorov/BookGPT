import Foundation
import RevenueCat

struct PaywallPlan: Identifiable, Equatable {
    let id: String
    let productID: String
    let title: String
    let price: String
    let billingDetail: String
    let trialDetail: String?
}

protocol PaywallServicing {
    func fetchPlans() async throws -> [PaywallPlan]
    func purchase(planID: String) async throws -> Bool
    func restorePurchases() async throws -> Bool
}

final class RevenueCatPaywallService: PaywallServicing {
    private var packagesByPlanID: [String: Package] = [:]

    func fetchPlans() async throws -> [PaywallPlan] {
        try ensureConfigured()
        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.offering(identifier: AppConfig.revenueCatOfferingID) else {
            return []
        }

        packagesByPlanID = offering.availablePackages.reduce(into: [:]) { result, package in
            result[package.identifier] = package
        }

        let orderedPackages = offering.availablePackages.sorted { lhs, rhs in
            rank(for: lhs.packageType) < rank(for: rhs.packageType)
        }

        return orderedPackages.map { package in
            let product = package.storeProduct
            return PaywallPlan(
                id: package.identifier,
                productID: product.productIdentifier,
                title: title(for: package),
                price: product.localizedPriceString,
                billingDetail: billingDetail(for: product),
                trialDetail: trialDetail(for: product)
            )
        }
    }

    func purchase(planID: String) async throws -> Bool {
        try ensureConfigured()
        guard let package = packagesByPlanID[planID] else { return false }
        let result = try await Purchases.shared.purchase(package: package)
        return hasActiveSubscription(in: result.customerInfo)
    }

    func restorePurchases() async throws -> Bool {
        try ensureConfigured()
        let customerInfo = try await Purchases.shared.restorePurchases()
        return hasActiveSubscription(in: customerInfo)
    }

    private func ensureConfigured() throws {
        if Purchases.isConfigured {
            return
        }

        guard !AppConfig.revenueCatAPIKey.isEmpty else {
            throw NSError(domain: "RevenueCatPaywallService", code: 1, userInfo: [NSLocalizedDescriptionKey: "RevenueCat API key missing."])
        }

        Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey)
    }

    private func hasActiveSubscription(in customerInfo: CustomerInfo) -> Bool {
        let activeSubscriptions = customerInfo.activeSubscriptions
        return activeSubscriptions.contains(AppConfig.revenueCatAnnualProductID) ||
            activeSubscriptions.contains(AppConfig.revenueCatWeeklyProductID)
    }

    private func title(for package: Package) -> String {
        switch package.packageType {
        case .annual:
            return "Annual"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        default:
            return "Plan"
        }
    }

    private func rank(for packageType: PackageType) -> Int {
        switch packageType {
        case .annual:
            return 0
        case .weekly:
            return 1
        case .monthly:
            return 2
        default:
            return 3
        }
    }

    private func billingDetail(for product: StoreProduct) -> String {
        guard let period = product.subscriptionPeriod else {
            return "Billed \(product.localizedPriceString)"
        }

        switch period.unit {
        case .day:
            return "Billed every \(period.value) day(s)"
        case .week:
            return "Billed every \(period.value) week(s)"
        case .month:
            return "Billed every \(period.value) month(s)"
        case .year:
            return "Billed every \(period.value) year(s)"
        @unknown default:
            return "Billed periodically"
        }
    }

    private func trialDetail(for product: StoreProduct) -> String? {
        guard let discount = product.introductoryDiscount else {
            return nil
        }

        let period = discount.subscriptionPeriod
        switch period.unit {
        case .day:
            return "\(period.value)-day trial"
        case .week:
            return "\(period.value)-week trial"
        case .month:
            return "\(period.value)-month trial"
        case .year:
            return "\(period.value)-year trial"
        @unknown default:
            return "Intro offer available"
        }
    }
}

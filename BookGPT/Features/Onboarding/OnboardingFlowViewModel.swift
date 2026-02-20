import Foundation
import Combine

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case hook
        case genres
        case readingGoal
        case archetypes
        case conversationVibe
        case visualStyle
        case bookTitle
        case visualization
        case firstMessage
        case personalization
        case whatsIncluded
        case paywall
    }

    @Published private(set) var steps: [Step]
    @Published private(set) var currentStep: Step

    @Published var selectedGenres: Set<String> = []
    @Published var selectedReadingGoal: String?

    @Published var selectedArchetypes: Set<String> = []
    @Published var selectedConversationVibe: String?

    @Published var selectedVisualStyle: String?
    @Published var bookTitle: String = ""

    @Published private(set) var isVisualizationLoading = false
    @Published private(set) var hasVisualizationReady = false
    @Published private(set) var generatedVisualization: OnboardingCharacterVisualization?
    @Published private(set) var visualizationErrorMessage: String?
    @Published private(set) var personalizationProgress: Double = 0
    @Published private(set) var hasPersonalizationReady = false
    @Published private(set) var activeReviewIndex: Int = 0

    @Published private(set) var paywallPlans: [PaywallPlan] = []
    @Published private(set) var showsPaywallCloseButton = false
    @Published var selectedPlanID: String?
    @Published private(set) var isPaywallLoading = false
    @Published private(set) var paywallErrorMessage: String?
    @Published private(set) var isProcessingPurchase = false
    @Published private(set) var purchaseCompleted = false

    let selectedHook: String
    private let visualizationService: any OnboardingCharacterVisualizing
    private let paywallService: any PaywallServicing
    private var personalizationTask: Task<Void, Never>?

    init(
        startAtPaywall: Bool,
        visualizationService: any OnboardingCharacterVisualizing = WikipediaCharacterVisualizationService(),
        paywallService: any PaywallServicing = RevenueCatPaywallService()
    ) {
        if startAtPaywall {
            self.steps = [.paywall]
            self.currentStep = .paywall
        } else {
            self.steps = Step.allCases
            self.currentStep = .hook
        }

        self.visualizationService = visualizationService
        self.paywallService = paywallService
        self.selectedHook = OnboardingContent.hookOptions.randomElement() ?? OnboardingContent.hookOptions[0]
    }

    deinit {
        personalizationTask?.cancel()
    }

    var canGoBack: Bool {
        indexOfCurrentStep > 0
    }

    var isOnPaywall: Bool {
        currentStep == .paywall
    }

    var progressValue: Double {
        guard steps.count > 1 else { return 1 }
        return Double(indexOfCurrentStep + 1) / Double(steps.count)
    }

    var primaryButtonTitle: String {
        switch currentStep {
        case .hook:
            return "Begin"
        case .visualization:
            return hasVisualizationReady ? "Continue" : "Creating..."
        case .personalization:
            return hasPersonalizationReady ? "Continue" : "Preparing..."
        case .paywall:
            if purchaseCompleted {
                return "Enter App"
            }
            return isProcessingPurchase ? "Processing..." : "Unlock BookGPT"
        default:
            return "Continue"
        }
    }

    var isPrimaryActionEnabled: Bool {
        switch currentStep {
        case .genres:
            return !selectedGenres.isEmpty
        case .readingGoal:
            return selectedReadingGoal != nil
        case .archetypes:
            return !selectedArchetypes.isEmpty
        case .conversationVibe:
            return selectedConversationVibe != nil
        case .visualStyle:
            return selectedVisualStyle != nil
        case .bookTitle:
            return !bookTitle.trimmed.isEmpty
        case .visualization:
            return hasVisualizationReady
        case .personalization:
            return hasPersonalizationReady
        case .paywall:
            return !isProcessingPurchase && !isPaywallLoading && selectedPlanID != nil
        default:
            return true
        }
    }

    var primaryArchetype: String {
        selectedArchetypes.first ?? "Protagonist"
    }

    var generatedFirstMessage: String {
        let resolvedBook = bookTitle.trimmed.isEmpty ? "your chosen book" : bookTitle.trimmed
        return "I have been waiting between the pages of \(resolvedBook). I can already sense your curiosity. Ask me what no one else dares to ask... see you in chat."
    }

    func goBack() {
        guard canGoBack else { return }
        currentStep = steps[indexOfCurrentStep - 1]
    }

    func advance() {
        guard isPrimaryActionEnabled else { return }
        guard !isOnPaywall else { return }

        if currentStep == .bookTitle {
            startVisualizationGeneration()
        }

        guard indexOfCurrentStep + 1 < steps.count else { return }
        currentStep = steps[indexOfCurrentStep + 1]
    }

    func purchase(onCompletion: (() -> Void)? = nil) {
        guard !isProcessingPurchase else { return }
        guard let selectedPlanID else { return }

        isProcessingPurchase = true
        Task {
            defer { isProcessingPurchase = false }
            do {
                let isActive = try await paywallService.purchase(planID: selectedPlanID)
                purchaseCompleted = isActive
                if isActive {
                    onCompletion?()
                }
            } catch {
                paywallErrorMessage = "Purchase failed. Please try again."
            }
        }
    }

    func restorePurchase(onCompletion: (() -> Void)? = nil) {
        guard !isProcessingPurchase else { return }
        isProcessingPurchase = true

        Task {
            defer { isProcessingPurchase = false }
            do {
                let isActive = try await paywallService.restorePurchases()
                purchaseCompleted = isActive
                if isActive {
                    onCompletion?()
                } else {
                    paywallErrorMessage = "No active subscription found to restore."
                }
            } catch {
                paywallErrorMessage = "Restore failed. Please try again."
            }
        }
    }

    func loadPaywallIfNeeded() {
        guard paywallPlans.isEmpty, !isPaywallLoading else { return }
        isPaywallLoading = true
        paywallErrorMessage = nil

        Task {
            do {
                let payload = try await paywallService.fetchPaywall()
                paywallPlans = payload.plans
                showsPaywallCloseButton = payload.showCloseButton
                selectedPlanID = payload.plans.first?.id
                isPaywallLoading = false
            } catch {
                isPaywallLoading = false
                paywallErrorMessage = "Could not load subscription options."
            }
        }
    }

    func usePopularBook(_ title: String) {
        bookTitle = title
    }

    func startVisualizationGeneration() {
        guard !isVisualizationLoading else { return }
        generatedVisualization = nil
        visualizationErrorMessage = nil
        hasVisualizationReady = false
        isVisualizationLoading = true

        let selectedBook = bookTitle.trimmed
        Task {
            do {
                let visualization = try await visualizationService.generateCharacterVisualization(for: selectedBook)
                isVisualizationLoading = false
                generatedVisualization = visualization
                hasVisualizationReady = true
            } catch {
                isVisualizationLoading = false
                hasVisualizationReady = false
                visualizationErrorMessage = "Could not generate a character portrait for this title yet. Try another book."
            }
        }
    }

    func startPersonalizationSequenceIfNeeded() {
        guard !hasPersonalizationReady, personalizationTask == nil else { return }

        personalizationProgress = 0
        activeReviewIndex = 0

        personalizationTask = Task { [weak self] in
            guard let self else { return }

            let totalTicks = 80
            let tickDurationNs: UInt64 = 100_000_000
            let reviewDurationSeconds = 8.0 / 3.0

            for tick in 1...totalTicks {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: tickDurationNs)

                let elapsedSeconds = Double(tick) * 0.1
                personalizationProgress = Double(tick) / Double(totalTicks)
                activeReviewIndex = min(
                    max(0, OnboardingContent.testimonials.count - 1),
                    Int(elapsedSeconds / reviewDurationSeconds)
                )
            }

            hasPersonalizationReady = true
            personalizationTask = nil
        }
    }

    func userSelectedReviewIndex(_ index: Int) {
        guard !OnboardingContent.testimonials.isEmpty else { return }
        let boundedIndex = min(max(index, 0), OnboardingContent.testimonials.count - 1)
        activeReviewIndex = boundedIndex
    }

    private var indexOfCurrentStep: Int {
        steps.firstIndex(of: currentStep) ?? 0
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

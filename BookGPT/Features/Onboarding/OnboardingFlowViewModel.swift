import Foundation
import Combine

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case hook
        case genres
        case favoriteBooks
        case readingGoal
        case archetypes
        case conversationVibe
        case visualStyle
        case bookTitle
        case visualization
        case firstMessage
        case personalization
        case socialProof
        case whatsIncluded
        case paywall
    }

    enum PlanOption {
        case annual
        case monthly
    }

    @Published private(set) var steps: [Step]
    @Published private(set) var currentStep: Step

    @Published var selectedGenres: Set<String> = []
    @Published var favoriteBooks: [String] = [""]
    @Published var skippedFavoriteBooks = false
    @Published var selectedReadingGoal: String?

    @Published var selectedArchetypes: Set<String> = []
    @Published var selectedConversationVibe: String?

    @Published var selectedVisualStyle: String?
    @Published var bookTitle: String = ""

    @Published private(set) var isVisualizationLoading = false
    @Published private(set) var hasVisualizationReady = false
    @Published private(set) var isSocialProofLoading = false
    @Published private(set) var hasSocialProofReady = false

    @Published var selectedPlan: PlanOption = .annual
    @Published private(set) var isProcessingPurchase = false
    @Published private(set) var purchaseCompleted = false

    let selectedHook: String

    init(startAtPaywall: Bool) {
        if startAtPaywall {
            self.steps = [.paywall]
            self.currentStep = .paywall
        } else {
            self.steps = Step.allCases
            self.currentStep = .hook
        }

        self.selectedHook = OnboardingContent.hookOptions.randomElement() ?? OnboardingContent.hookOptions[0]
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
        case .paywall:
            return purchaseCompleted ? "Enter App" : "Unlock BookGPT"
        default:
            return "Continue"
        }
    }

    var isPrimaryActionEnabled: Bool {
        switch currentStep {
        case .genres:
            return !selectedGenres.isEmpty
        case .favoriteBooks:
            return skippedFavoriteBooks || favoriteBooks.contains { !$0.trimmed.isEmpty }
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
        case .socialProof:
            return hasSocialProofReady
        case .paywall:
            return !isProcessingPurchase
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
            startVisualizationStub()
        }
        if currentStep == .personalization {
            startSocialProofPreparationStub()
        }

        guard indexOfCurrentStep + 1 < steps.count else { return }
        currentStep = steps[indexOfCurrentStep + 1]
    }

    func restorePurchaseStub(onCompletion: (() -> Void)? = nil) {
        isProcessingPurchase = true
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            isProcessingPurchase = false
            purchaseCompleted = true
            onCompletion?()
        }
    }

    func purchaseStub(onCompletion: (() -> Void)? = nil) {
        guard !isProcessingPurchase else { return }
        isProcessingPurchase = true
        Task {
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            isProcessingPurchase = false
            purchaseCompleted = true
            onCompletion?()
        }
    }

    func startVisualizationStub() {
        guard !isVisualizationLoading else { return }
        hasVisualizationReady = false
        isVisualizationLoading = true

        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            isVisualizationLoading = false
            hasVisualizationReady = true
        }
    }

    func startSocialProofPreparationStub() {
        guard !isSocialProofLoading, !hasSocialProofReady else { return }
        isSocialProofLoading = true

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isSocialProofLoading = false
            hasSocialProofReady = true
        }
    }

    func addFavoriteBookField() {
        guard favoriteBooks.count < 4 else { return }
        favoriteBooks.append("")
    }

    func updateFavoriteBook(at index: Int, value: String) {
        guard favoriteBooks.indices.contains(index) else { return }
        favoriteBooks[index] = value
        if !value.trimmed.isEmpty {
            skippedFavoriteBooks = false
        }
    }

    func markFavoriteBooksSkipped() {
        skippedFavoriteBooks = true
        favoriteBooks = [""]
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

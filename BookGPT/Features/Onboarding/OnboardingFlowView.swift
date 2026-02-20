import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var viewModel: OnboardingFlowViewModel
    @State private var transitionEdge: Edge = .trailing
    private let screenAnimation = Animation.easeInOut(duration: 0.35)

    private let onReachedPaywall: () -> Void
    private let onPurchaseCompleted: () -> Void

    init(
        startAtPaywall: Bool,
        onReachedPaywall: @escaping () -> Void,
        onPurchaseCompleted: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: OnboardingFlowViewModel(startAtPaywall: startAtPaywall))
        self.onReachedPaywall = onReachedPaywall
        self.onPurchaseCompleted = onPurchaseCompleted
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    ZStack {
                        stepContent
                            .id(viewModel.currentStep)
                            .transition(stepTransition)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                    .padding(.horizontal, 20)
                }

                if !viewModel.isOnPaywall {
                    primaryActionButton
                        .padding(.horizontal, 20)
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 12)
        }
        .foregroundStyle(BrandBook.Colors.primaryText)
        .onChange(of: viewModel.currentStep) { _, step in
            if step == .paywall {
                onReachedPaywall()
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if viewModel.steps.count > 1 {
            VStack(spacing: 10) {
                HStack {
                    if viewModel.canGoBack {
                        Button {
                            transitionEdge = .leading
                            withAnimation(screenAnimation) {
                                viewModel.goBack()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .padding(10)
                                .background(BrandBook.Colors.surface)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(width: 40, height: 40)
                    }
                    Spacer()
                }

                ProgressView(value: viewModel.progressValue)
                    .tint(BrandBook.Colors.gold)
                    .background(BrandBook.Colors.surfaceMuted.opacity(0.5))
                    .clipShape(Capsule())
                    .animation(screenAnimation, value: viewModel.progressValue)
            }
            .padding(.horizontal, 20)
        }
    }

    private var stepTransition: AnyTransition {
        let insertion = AnyTransition.move(edge: transitionEdge).combined(with: .opacity)
        let removalEdge: Edge = transitionEdge == .trailing ? .leading : .trailing
        let removal = AnyTransition.move(edge: removalEdge).combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }

    private var backgroundLayer: some View {
        ZStack {
            BrandBook.Colors.background.ignoresSafeArea()
            LinearGradient(
                colors: [
                    BrandBook.Colors.gold.opacity(0.18),
                    BrandBook.Colors.background,
                    BrandBook.Colors.surface.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(BrandBook.Colors.gold.opacity(0.12))
                .frame(width: 260, height: 260)
                .offset(x: 120, y: -280)
            Circle()
                .fill(BrandBook.Colors.paper.opacity(0.08))
                .frame(width: 220, height: 220)
                .offset(x: -140, y: 300)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .hook:
            hookStep
        case .genres:
            genresStep
        case .favoriteBooks:
            favoriteBooksStep
        case .readingGoal:
            readingGoalStep
        case .archetypes:
            archetypesStep
        case .conversationVibe:
            conversationVibeStep
        case .visualStyle:
            visualStyleStep
        case .bookTitle:
            bookTitleStep
        case .visualization:
            visualizationStep
        case .firstMessage:
            firstMessageStep
        case .personalization:
            personalizationStep
        case .socialProof:
            socialProofStep
        case .whatsIncluded:
            whatsIncludedStep
        case .paywall:
            paywallStep
        }
    }

    private var primaryActionButton: some View {
        Button {
            transitionEdge = .trailing
            withAnimation(screenAnimation) {
                viewModel.advance()
            }
        } label: {
            Text(viewModel.primaryButtonTitle)
                .font(BrandBook.Typography.body())
                .foregroundStyle(BrandBook.Colors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(viewModel.isPrimaryActionEnabled ? BrandBook.Colors.gold : BrandBook.Colors.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isPrimaryActionEnabled)
    }

    private var hookStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("BookGPT")
                .font(BrandBook.Typography.title(size: 36))
            Text(viewModel.selectedHook)
                .font(BrandBook.Typography.section(size: 25))
                .foregroundStyle(BrandBook.Colors.paper)

            Text("Character-true visuals and in-character chat moments, tailored to how you read.")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)
                .padding(.top, 2)

            featureStrip([
                "Portraits from book context",
                "Persona-first conversations",
                "Built for serious readers"
            ])
        }
        .padding(20)
        .background(BrandBook.Colors.surface.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var genresStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Choose your favorite genres")
            Text("Pick at least one. We will tune character picks and tone to these genres.")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)

            flowChips(
                values: OnboardingContent.genres,
                selection: viewModel.selectedGenres,
                onTap: toggleGenre
            )
        }
    }

    private var favoriteBooksStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Top books you love")
            Text("Add one title now. Add more only if you want.")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)

            VStack(spacing: 12) {
                ForEach(0..<viewModel.favoriteBooks.count, id: \.self) { index in
                    TextField("Book #\(index + 1)", text: bindingForBook(at: index))
                        .textInputAutocapitalization(.words)
                        .font(BrandBook.Typography.body())
                        .padding(12)
                        .background(BrandBook.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if viewModel.favoriteBooks.count < 4 {
                    Button {
                        viewModel.addFavoriteBookField()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add another book")
                            Spacer()
                        }
                        .font(BrandBook.Typography.body(size: 16))
                        .foregroundStyle(BrandBook.Colors.paper)
                        .padding(12)
                        .background(BrandBook.Colors.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Button("Skip for now") {
                    viewModel.markFavoriteBooksSkipped()
                }
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var readingGoalStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("What do you want most?")
            Text("Select your primary reading outcome.")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)

            VStack(spacing: 10) {
                ForEach(OnboardingContent.readingGoals, id: \.self) { goal in
                    selectionRow(
                        title: goal,
                        subtitle: goalSubtitle(goal),
                        isSelected: viewModel.selectedReadingGoal == goal
                    ) {
                        viewModel.selectedReadingGoal = goal
                    }
                }
            }
        }
    }

    private var archetypesStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Character types you want to talk to")
            Text("Pick one or more archetypes.")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)

            flowChips(
                values: OnboardingContent.characterArchetypes,
                selection: viewModel.selectedArchetypes,
                onTap: toggleArchetype
            )
        }
    }

    private var conversationVibeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("How should the character engage you?")
            Text("This sets the default style for opening replies.")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)

            VStack(spacing: 10) {
                ForEach(OnboardingContent.conversationVibes, id: \.self) { vibe in
                    selectionRow(
                        title: vibe,
                        subtitle: vibeSubtitle(vibe),
                        isSelected: viewModel.selectedConversationVibe == vibe
                    ) {
                        viewModel.selectedConversationVibe = vibe
                    }
                }
            }
        }
    }

    private var visualStyleStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Portrait style preference")
            Text("Choose how characters should look when visualized.")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)

            VStack(spacing: 10) {
                ForEach(OnboardingContent.visualStyles, id: \.self) { style in
                    selectionRow(
                        title: style,
                        subtitle: styleSubtitle(style),
                        isSelected: viewModel.selectedVisualStyle == style
                    ) {
                        viewModel.selectedVisualStyle = style
                    }
                }
            }
        }
    }

    private var bookTitleStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Pick one book to start")
            Text("We will generate one character portrait and opening line from this context.")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)

            TextField("Enter a book title", text: $viewModel.bookTitle)
                .textInputAutocapitalization(.words)
                .font(BrandBook.Typography.body())
                .padding(12)
                .background(BrandBook.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var visualizationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Character Visualization Reveal")

            if viewModel.isVisualizationLoading {
                VStack(spacing: 14) {
                    ProgressView()
                        .tint(BrandBook.Colors.gold)
                    Text("Generating portrait from book context...")
                        .font(BrandBook.Typography.caption())
                        .foregroundStyle(BrandBook.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 340)
                .background(BrandBook.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                CharacterPortraitStubView(bookTitle: viewModel.bookTitle.trimmedOrFallback("Selected Book"))
            }

            Text("Single portrait preview for now. Full generation pipeline can be connected next.")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)
        }
        .task {
            if !viewModel.hasVisualizationReady && !viewModel.isVisualizationLoading {
                viewModel.startVisualizationStub()
            }
        }
    }

    private var firstMessageStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("First message preview")
            Text("Mock opening line from a \(viewModel.primaryArchetype.lowercased()) in your selected book.")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)

            VStack(alignment: .leading, spacing: 8) {
                Text("Character")
                    .font(BrandBook.Typography.caption())
                    .foregroundStyle(BrandBook.Colors.secondaryText)

                Text(viewModel.generatedFirstMessage)
                    .font(BrandBook.Typography.body())
                    .foregroundStyle(BrandBook.Colors.primaryText)
                    .padding(14)
                    .background(BrandBook.Colors.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var personalizationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Your experience is ready")

            VStack(alignment: .leading, spacing: 12) {
                summaryLine("Genres", value: viewModel.selectedGenres.sorted().joined(separator: ", "))
                summaryLine("Reading goal", value: viewModel.selectedReadingGoal ?? "Not selected")
                summaryLine("Character style", value: viewModel.selectedConversationVibe ?? "Not selected")
                summaryLine("Portrait mood", value: viewModel.selectedVisualStyle ?? "Not selected")
            }
            .padding(14)
            .background(BrandBook.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var socialProofStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.isSocialProofLoading || !viewModel.hasSocialProofReady {
                stepTitle("Preparing your personalized library")
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(BrandBook.Colors.gold)
                    Text("Analyzing your taste and preparing your character setup...")
                        .font(BrandBook.Typography.body(size: 16))
                        .multilineTextAlignment(.center)
                    Text("This takes a moment and unlocks a better first experience after purchase.")
                        .font(BrandBook.Typography.caption())
                        .foregroundStyle(BrandBook.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .padding(.horizontal, 16)
                .background(BrandBook.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                stepTitle("Loved by readers")

                HStack(spacing: 10) {
                    Text("4.9")
                        .font(BrandBook.Typography.title(size: 36))
                    Text("★★★★★")
                        .font(BrandBook.Typography.section(size: 24))
                    Spacer()
                }
                .foregroundStyle(BrandBook.Colors.gold)

                VStack(spacing: 10) {
                    ForEach(OnboardingContent.testimonials) { testimonial in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\"\(testimonial.quote)\"")
                                .font(BrandBook.Typography.body(size: 16))
                            Text(testimonial.author)
                                .font(BrandBook.Typography.caption())
                                .foregroundStyle(BrandBook.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(BrandBook.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
        .task {
            viewModel.startSocialProofPreparationStub()
        }
    }

    private var whatsIncludedStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("What’s included")

            VStack(spacing: 10) {
                ForEach(OnboardingContent.includedFeatures, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(BrandBook.Colors.gold)
                            .padding(.top, 1)
                        Text(item)
                            .font(BrandBook.Typography.body())
                        Spacer()
                    }
                    .padding(12)
                    .background(BrandBook.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private var paywallStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Unlock BookGPT")

            Text("Your personalized setup is ready. Full access starts now.")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)

            paywallPlans
            legalAndActions
            faqSection

            if viewModel.purchaseCompleted {
                confirmationPanel
            }
        }
    }

    private var paywallPlans: some View {
        VStack(spacing: 10) {
            planCard(
                title: "Annual",
                price: "$59.99/year",
                detail: "7-day free trial, then billed $59.99 yearly.",
                isSelected: viewModel.selectedPlan == .annual,
                badge: "Best Value"
            ) {
                viewModel.selectedPlan = .annual
            }

            planCard(
                title: "Monthly",
                price: "$9.99/month",
                detail: "Billed monthly with auto-renewal.",
                isSelected: viewModel.selectedPlan == .monthly,
                badge: nil
            ) {
                viewModel.selectedPlan = .monthly
            }
        }
    }

    private var legalAndActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By subscribing, your plan auto-renews unless canceled at least 24 hours before the end of the current period.")
                .font(BrandBook.Typography.caption(size: 14))
                .foregroundStyle(BrandBook.Colors.secondaryText)

            if viewModel.selectedPlan == .annual {
                Text("Total billed amount: $59.99 per year after trial. Trial terms: 7 days free, then annual billing begins.")
                    .font(BrandBook.Typography.caption(size: 14))
                    .foregroundStyle(BrandBook.Colors.secondaryText)
            } else {
                Text("Total billed amount: $9.99 per month. Trial terms: none for monthly plan.")
                    .font(BrandBook.Typography.caption(size: 14))
                    .foregroundStyle(BrandBook.Colors.secondaryText)
            }

            Button {
                viewModel.purchaseStub()
            } label: {
                HStack {
                    if viewModel.isProcessingPurchase {
                        ProgressView()
                            .tint(BrandBook.Colors.background)
                    }
                    Text(viewModel.isProcessingPurchase ? "Processing..." : "Unlock BookGPT")
                }
                .font(BrandBook.Typography.body())
                .foregroundStyle(BrandBook.Colors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(BrandBook.Colors.gold)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .disabled(viewModel.isProcessingPurchase)

            HStack {
                Button("Restore") {
                    viewModel.restorePurchaseStub()
                }

                Spacer()

                Link("Terms", destination: URL(string: "https://example.com/terms")!)
                Link("Privacy", destination: URL(string: "https://example.com/privacy")!)
            }
            .font(BrandBook.Typography.caption(size: 14))
            .foregroundStyle(BrandBook.Colors.secondaryText)
        }
        .padding(14)
        .background(BrandBook.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FAQ")
                .font(BrandBook.Typography.section(size: 20))

            faqRow(
                question: "Can I cancel anytime?",
                answer: "Yes. You can cancel in Apple ID subscription settings. Access remains active until period end."
            )
            faqRow(
                question: "What does in-character mean?",
                answer: "Replies are generated to stay aligned with your selected character persona and book context."
            )
            faqRow(
                question: "Are there limitations?",
                answer: "Outputs are AI-generated and may occasionally miss nuance. You can regenerate or retry messages."
            )
            faqRow(
                question: "Is there a free mode?",
                answer: "No. BookGPT is a paid-only experience."
            )
        }
        .padding(14)
        .background(BrandBook.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var confirmationPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Purchase confirmed")
                .font(BrandBook.Typography.section(size: 19))
            Text("Everything is ready: personalized character visuals and your first in-character conversation.")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)
            Button("Enter App") {
                onPurchaseCompleted()
            }
            .font(BrandBook.Typography.body())
            .foregroundStyle(BrandBook.Colors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(BrandBook.Colors.gold)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(BrandBook.Colors.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func stepTitle(_ text: String) -> some View {
        Text(text)
            .font(BrandBook.Typography.section(size: 27))
            .foregroundStyle(BrandBook.Colors.paper)
    }

    private func toggleGenre(_ genre: String) {
        if viewModel.selectedGenres.contains(genre) {
            viewModel.selectedGenres.remove(genre)
        } else {
            viewModel.selectedGenres.insert(genre)
        }
    }

    private func toggleArchetype(_ archetype: String) {
        if viewModel.selectedArchetypes.contains(archetype) {
            viewModel.selectedArchetypes.remove(archetype)
        } else {
            viewModel.selectedArchetypes.insert(archetype)
        }
    }

    private func flowChips(values: [String], selection: Set<String>, onTap: @escaping (String) -> Void) -> some View {
        VStack(spacing: 10) {
            ForEach(values, id: \.self) { value in
                let selected = selection.contains(value)
                Button {
                    onTap(value)
                } label: {
                    HStack(spacing: 10) {
                        Text(value)
                            .font(BrandBook.Typography.body(size: 15))
                            .foregroundStyle(selected ? BrandBook.Colors.background : BrandBook.Colors.primaryText)
                        Spacer()
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected ? BrandBook.Colors.background : BrandBook.Colors.secondaryText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(selected ? BrandBook.Colors.gold : BrandBook.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func featureStrip(_ items: [String]) -> some View {
        VStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(BrandBook.Colors.gold)
                    Text(item)
                        .font(BrandBook.Typography.body(size: 16))
                    Spacer()
                }
                .padding(10)
                .background(BrandBook.Colors.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func selectionRow(title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(BrandBook.Typography.body())
                    Text(subtitle)
                        .font(BrandBook.Typography.caption(size: 14))
                        .foregroundStyle(BrandBook.Colors.secondaryText)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? BrandBook.Colors.gold : BrandBook.Colors.secondaryText)
            }
            .padding(12)
            .background(isSelected ? BrandBook.Colors.surfaceMuted : BrandBook.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func planCard(title: String, price: String, detail: String, isSelected: Bool, badge: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(BrandBook.Typography.section(size: 18))
                        if let badge {
                            Text(badge)
                                .font(BrandBook.Typography.caption(size: 12))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(BrandBook.Colors.gold.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    Text(price)
                        .font(BrandBook.Typography.body())
                    Text(detail)
                        .font(BrandBook.Typography.caption(size: 14))
                        .foregroundStyle(BrandBook.Colors.secondaryText)
                }
                Spacer()
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? BrandBook.Colors.gold : BrandBook.Colors.secondaryText)
            }
            .padding(12)
            .background(isSelected ? BrandBook.Colors.surfaceMuted : BrandBook.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func faqRow(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(question)
                .font(BrandBook.Typography.body(size: 16))
            Text(answer)
                .font(BrandBook.Typography.caption(size: 14))
                .foregroundStyle(BrandBook.Colors.secondaryText)
        }
    }

    private func summaryLine(_ title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(title):")
                .font(BrandBook.Typography.body(size: 16))
                .foregroundStyle(BrandBook.Colors.paper)
            Text(value)
                .font(BrandBook.Typography.body(size: 16))
                .foregroundStyle(BrandBook.Colors.primaryText)
            Spacer()
        }
    }

    private func bindingForBook(at index: Int) -> Binding<String> {
        Binding(
            get: { viewModel.favoriteBooks[index] },
            set: { viewModel.updateFavoriteBook(at: index, value: $0) }
        )
    }

    private func goalSubtitle(_ goal: String) -> String {
        switch goal {
        case "Fun immersion":
            return "Stay in the story world and enjoy character moments."
        case "Deep analysis":
            return "Explore motives, themes, and decisions in context."
        case "Language practice":
            return "Practice nuanced conversation through literary personas."
        case "Companionship":
            return "Build a reading ritual with familiar characters."
        default:
            return ""
        }
    }

    private func vibeSubtitle(_ vibe: String) -> String {
        switch vibe {
        case "Guide me":
            return "Supportive explanations and thoughtful nudges."
        case "Challenge me":
            return "Pushback, sharper takes, harder questions."
        case "Witty banter":
            return "Playful pacing with personality-driven replies."
        case "Direct and sharp":
            return "Concise, high-signal exchanges."
        default:
            return ""
        }
    }

    private func styleSubtitle(_ style: String) -> String {
        switch style {
        case "Cinematic realism":
            return "Detailed and dramatic modern look."
        case "Vintage engraving":
            return "Classic etched style inspired by old editions."
        case "Painterly classic":
            return "Soft brushwork with literary atmosphere."
        default:
            return ""
        }
    }
}

private struct CharacterPortraitStubView: View {
    let bookTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                BrandBook.Colors.surfaceMuted,
                                BrandBook.Colors.surface,
                                BrandBook.Colors.gold.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.artframe")
                        .font(.system(size: 72, weight: .semibold))
                        .foregroundStyle(BrandBook.Colors.gold)
                    Text("Character Portrait")
                        .font(BrandBook.Typography.section(size: 20))
                        .foregroundStyle(BrandBook.Colors.paper)
                    Text("Stub image")
                        .font(BrandBook.Typography.caption(size: 14))
                        .foregroundStyle(BrandBook.Colors.secondaryText)
                }
            }
            .frame(height: 320)

            Text("Generated from \(bookTitle)")
                .font(BrandBook.Typography.caption())
                .foregroundStyle(BrandBook.Colors.secondaryText)
        }
    }
}

private extension String {
    func trimmedOrFallback(_ fallback: String) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

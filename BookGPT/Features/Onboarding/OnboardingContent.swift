import Foundation

enum OnboardingContent {
    static let hookOptions: [String] = [
        "Meet the heroes and villains exactly as the book describes them.",
        "Step inside your favorite novel and talk to its characters.",
        "Your next conversation starts in a book you already love.",
        "See characters as written. Hear them speak in character.",
        "From page to persona: visuals + voice true to the book.",
        "Turn any classic into a live character experience.",
        "Not summaries. Real character perspectives from the story world.",
        "Bring literary characters to life in seconds.",
        "Visualize the cast. Start the conversation.",
        "If you could text one book character, who would it be?",
        "Read less recap, ask better questions to the character directly.",
        "Your personal literary companion, in character and in context.",
        "See them. Message them. Stay in the book universe.",
        "Character-accurate portraits and first messages from the story.",
        "Open a book. Unlock a cast."
    ]

    static let genres: [String] = [
        "Fantasy", "Mystery", "Romance", "Sci-Fi", "Classics", "Thriller", "Historical", "Dystopian"
    ]

    static let readingGoals: [String] = [
        "Fun immersion",
        "Deep analysis",
        "Language practice",
        "Companionship"
    ]

    static let characterArchetypes: [String] = [
        "Mentor", "Antihero", "Strategist", "Rebel", "Villain", "Dreamer", "Detective", "Sage"
    ]

    static let conversationVibes: [String] = [
        "Guide me",
        "Challenge me",
        "Witty banter",
        "Direct and sharp"
    ]

    static let visualStyles: [String] = [
        "Cinematic realism",
        "Vintage engraving",
        "Painterly classic"
    ]

    static let popularBooks: [String] = [
        "The Hobbit",
        "Pride and Prejudice",
        "The Great Gatsby"
    ]

    static let testimonials: [OnboardingTestimonial] = [
        OnboardingTestimonial(
            quote: "I opened one classic and instantly felt like I was inside the story.",
            author: "Early Reader"
        ),
        OnboardingTestimonial(
            quote: "The character portraits pulled me in before I even started chatting.",
            author: "Book Club Host"
        ),
        OnboardingTestimonial(
            quote: "Best way to explore motives and subtext without rereading chapters.",
            author: "Literature Student"
        )
    ]

    static let includedFeatures: [String] = [
        "Unlimited character chats",
        "Richer persona memory per session",
        "Visual character generation from book context"
    ]
}

struct OnboardingTestimonial: Identifiable {
    let id = UUID()
    let quote: String
    let author: String
}

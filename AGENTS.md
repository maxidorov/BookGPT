# AGENTS.md

## Product Goal (MVP)

Build an iOS MVP where a user:
1. Enters a book title on the main screen.
2. Sees a list of characters for that book.
3. Opens a chat with a selected character.

Keep scope narrow. Prefer reliable, understandable code over extra features.

## Tech and Architecture

- Language: Swift 5.9+
- Target: iOS 16+
- UI: SwiftUI app shell; Chat screen may bridge UIKit if needed
- Architecture: MVVM
- Concurrency: async/await
- Dependency management: Swift Package Manager

## Required Dependencies

- `ChatKit` from `/Users/maksimsidorov/Developer/ChatKit`
- `LLMKit` from `/Users/maksimsidorov/Developer/LLMKit`

Before changing integration behavior, read:
- `/Users/maksimsidorov/Developer/ChatKit/DOCUMENTATION.md`
- `/Users/maksimsidorov/Developer/ChatKit/ARCHITECTURE.md`
- `/Users/maksimsidorov/Developer/LLMKit/DOCUMENTATION.md`
- `/Users/maksimsidorov/Developer/LLMKit/ARCHITECTURE.md`

## MVVM Boundaries (Do Not Blur)

- View: rendering, user actions, navigation only.
- ViewModel: screen state, validation, async orchestration, error mapping.
- Model/Domain: entities and use-cases.
- Data layer: API clients, repositories, DTO mapping.

Views must not call LLM/network services directly.

## Feature Boundaries (MVP Only)

Include:
- Book search by title (single text field + button).
- Character list for selected book.
- Chat with selected character using `ChatKit` UI and `LLMKit` for response generation.

Exclude for MVP:
- Auth, payments, subscriptions
- Offline persistence
- Multi-book libraries and favorites
- Complex prompt-builder UI
- Streaming, voice, image generation

## Chat Behavior Rules

- System prompt must enforce roleplay as the selected character.
- Keep one conversation context per selected character session.
- On send:
  1. Add user message to chat.
  2. Send full mapped history to `LLMKit`.
  3. Insert assistant response into chat.
- Handle failures with user-visible retry path and non-blocking UI state.

## Quality Rules

- Apply SOLID pragmatically; avoid unnecessary abstractions.
- Prefer protocol seams at external boundaries (network, LLM client, repositories).
- Use `final` by default.
- Use dependency injection through initializers.
- No force unwraps in production flow.
- Keep files focused and small.

## Testing Strategy

Minimum required tests for MVP:
- ViewModel tests:
  - Book search validation and loading/error/success states.
  - Character selection and navigation intent.
  - Chat send flow success and failure.
- Mapping tests:
  - `ChatKit Message` <-> domain message mapping.
  - Domain message history -> `LLMMessage` mapping.
- Repository tests with mocks/stubs (no real network in unit tests).

## Definition of Done (MVP)

- All 3 screens work end-to-end.
- Chat works with selected character persona.
- Error and loading states are visible and recoverable.
- Architecture remains MVVM and understandable for future iteration.
- Tests cover critical flows and pass.

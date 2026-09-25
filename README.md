# SaaS Costs Monitor - macOS Menu Bar App

Monitor your LLM provider spending in real-time from the macOS menu bar.

## Architecture

```
Sources/
├── Core/
│   ├── CostFetcher.swift      # Protocol for all providers
│   └── CostCoordinator.swift  # Orchestrates fetching from all providers
├── Providers/
│   ├── AnthropicProvider.swift
│   ├── OpenAIProvider.swift
│   ├── GeminiProvider.swift
│   ├── GroqProvider.swift
│   ├── GrokProvider.swift
│   └── CerebrasProvider.swift
├── UI/
│   └── MenuBarManager.swift    # Menu bar UI controller
└── Utils/
    └── EnvLoader.swift         # Load .env.local file
```

## Design Principles

- **Modularity**: Each provider is independent, can be developed/tested separately
- **Small files**: Max ~150 lines per file, single responsibility
- **No overengineering**: Only what's needed, no premature abstractions
- **Code quality**: SwiftLint enforced, professional standards

## Setup

1. Ensure you have Swift 5.9+ and Xcode 15+
2. Clone/initialize the repository
3. Configure `.env.local` with your API keys (already set up)

## Code Quality

SwiftLint is configured in `.swiftlint.yml`. To validate:

```bash
swiftlint Sources/
```

Key rules enforced:
- Max 50 lines per function
- Max 200 lines per file
- Max 10 cyclomatic complexity
- Proper naming conventions
- No force unwrapping in production code

## Implementing Providers

Each provider implements `CostFetcher`:

```swift
struct MyProvider: CostFetcher {
    let providerName = "Provider Name"
    let apiKey: String?
    
    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["MY_API_KEY"]
    }
    
    func fetchCost() async throws -> Double {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }
        
        // 1. Call provider's billing/usage API
        // 2. Parse response
        // 3. Return total cost as Double
        
        return totalCost
    }
}
```

### Current Status

- ✅ Anthropic: Full implementation (example)
- 🔄 OpenAI: Needs API integration
- 🔄 Google Gemini: Needs GCP billing setup
- 🔄 Groq: Needs API integration
- 🔄 Grok (xAI): Needs API integration
- 🔄 Cerebras: Needs API integration

## Next Steps

1. Implement remaining providers
2. Create UI layer (SwiftUI menu bar)
3. Add refresh timer
4. Implement persistent cache
5. Create release build

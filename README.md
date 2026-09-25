# SaaS Costs Monitor - macOS Menu Bar App

Monitor your LLM provider spending in real-time from the macOS menu bar. 💰

A lightweight Swift app that displays aggregated costs from 8+ AI/LLM providers directly in your menu bar.

## Features

- 🔄 **Real-time cost tracking** - Automatic refresh every hour
- 📊 **Multi-provider support** - OpenAI, Anthropic, Google Gemini, Groq, Grok, Cerebras, ElevenLabs, Soniox
- 🔐 **Secure** - Uses `.env.local`, never stores credentials
- ⚡ **Fast** - Swift/AppKit, minimal resource usage
- 🎨 **Native UI** - macOS menu bar integration
- 📋 **Professional code** - SwiftLint validated, modular architecture

## Architecture

```
Sources/
├── Core/
│   ├── CostFetcher.swift       # Protocol for all providers
│   ├── CostCoordinator.swift   # Orchestrates parallel fetching
│   └── ProviderFactory.swift   # Auto-discovers enabled providers
├── Providers/
│   ├── AnthropicProvider.swift
│   ├── OpenAIProvider.swift
│   ├── GeminiProvider.swift
│   ├── GroqProvider.swift
│   ├── GrokProvider.swift
│   ├── CerebrasProvider.swift
│   ├── ElevenLabsProvider.swift
│   └── SonioxProvider.swift
├── UI/
│   ├── AppDelegate.swift       # App lifecycle
│   ├── MenuBarManager.swift    # Menu bar UI
│   └── CostUpdater.swift       # Background refresh
├── Utils/
│   ├── EnvLoader.swift         # .env.local parser
│   └── AppConfig.swift         # Configuration
└── main.swift                  # Entry point
```

## Quick Start

### Prerequisites
- macOS 12.0+
- Swift 5.9+
- Xcode 15+ (for building .app bundle)

### Setup

1. **Clone and configure**
   ```bash
   git clone https://github.com/cesarzea/sass-costs.git
   cd sass-costs
   
   # Copy your API keys to .env.local
   cp .env.local.example .env.local  # Then add your keys
   ```

2. **Build**
   ```bash
   # Debug build
   make build
   
   # Release build (optimized)
   make release
   ```

3. **Create Xcode project** (for .app bundle)
   - Open `Package.swift` in Xcode
   - Create new target with Info.plist
   - Copy `Info.plist` to project
   - Build & run

4. **Install**
   Move `.app` to `/Applications`

## Configuration

Edit `.env.local` with your provider API keys:

```bash
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-proj-...
GEMINI_API_KEY=AIzaSy...
GROQ_API_KEY=gsk_...
GROK_API_KEY=xai-...
CEREBRAS_API_KEY=csk-...
ELEVEN_LABS_KEY=sk_...
SONIOX_API_KEY=snx_...
```

Only configured keys will be monitored.

## Code Quality

All code passes SwiftLint validation:

```bash
make lint
```

Standards enforced:
- Max 50 lines per function
- Max 200 lines per file
- Max 10 cyclomatic complexity
- No force unwrapping
- Proper naming conventions

## Provider Status

| Provider | Status | Endpoint |
|----------|--------|----------|
| Anthropic | ✅ | `/v1/usage` |
| OpenAI | ✅ | `/v1/dashboard/billing/usage` |
| Google Gemini | ✅ | Cloud Billing API |
| Groq | ✅ | `/billing/usage` |
| Grok (xAI) | ✅ | `/v1/billing/usage` |
| Cerebras | ✅ | `/v1/billing/usage` |
| ElevenLabs | ✅ | `/v1/user` |
| Soniox | ✅ | `/v1/billing` |

## Development

### Adding a New Provider

1. Create `Sources/Providers/NewProvider.swift`
2. Implement `CostFetcher` protocol
3. Add to `ProviderFactory.swift`
4. Test with real API key

```swift
struct NewProvider: CostFetcher {
    let providerName = "Provider Name"
    let apiKey: String?
    
    func fetchCost() async throws -> Double {
        // Implementation
    }
}
```

### Testing

```bash
# Build debug version
make build

# Run with verbose output
RUST_LOG=debug .build/debug/SaaS-Costs
```

## Maintenance

- **SwiftLint**: Run before commits
- **Dependencies**: Swift stdlib only, no external deps
- **Versioning**: Follows semantic versioning

## License

MIT - See LICENSE file

## Support

Issues & PRs welcome at https://github.com/cesarzea/sass-costs

# Development Guide

## Project Structure

### Core Layer (`Sources/Core/`)
- **CostFetcher.swift** - Protocol that all providers implement
- **CostCoordinator.swift** - Actor that manages parallel cost fetching
- **ProviderFactory.swift** - Creates providers based on available API keys

### Provider Layer (`Sources/Providers/`)
Each provider file:
- ~40-60 lines (small, focused)
- Implements `CostFetcher` protocol
- Handles one API endpoint
- Includes private models for JSON decoding

### UI Layer (`Sources/UI/`)
- **AppDelegate.swift** - Application lifecycle
- **MenuBarManager.swift** - Menu bar UI and interactions
- **CostUpdater.swift** - Background refresh timer

### Utils Layer (`Sources/Utils/`)
- **EnvLoader.swift** - Parses .env.local
- **AppConfig.swift** - Centralized configuration

## Adding a Provider

### 1. Create Provider File

```swift
// Sources/Providers/MyProviderProvider.swift
import Foundation

struct MyProviderProvider: CostFetcher {
    let providerName = "My Provider"
    let apiKey: String?
    
    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["MYPROVIDER_API_KEY"]
    }
    
    func fetchCost() async throws -> Double {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }
        
        let url = URL(string: "https://api.myprovider.com/billing")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProviderError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let usage = try decoder.decode(MyProviderUsage.self, from: data)
        return usage.totalCost
    }
}

private struct MyProviderUsage: Codable {
    let totalCost: Double
}
```

### 2. Register in ProviderFactory

```swift
// In Sources/Core/ProviderFactory.swift
if env["MYPROVIDER_API_KEY"] != nil {
    providers.append(MyProviderProvider())
}
```

### 3. Add to .env.local.example

```
MYPROVIDER_API_KEY=your-key-here
```

### 4. Validate & Test

```bash
# Lint
make lint

# Build
make build

# Test (add to main.swift temporarily)
let provider = MyProviderProvider(apiKey: "test-key")
let cost = try await provider.fetchCost()
print("Cost: \(cost)")
```

## Code Standards

### SwiftLint Rules
- ✅ Max 50 lines per function
- ✅ Max 200 lines per file
- ✅ Max 10 cyclomatic complexity
- ✅ No force unwrapping
- ✅ Proper naming (camelCase, CapitalCase for types)

### Style Guidelines
- Use `let` by default, `var` only when needed
- Prefer `guard` over nested `if`
- Use actors for thread-safe state
- Async/await for concurrent operations
- Private by default, `public` explicitly

### Documentation
- One-line comments only (no multi-line blocks)
- Comment the WHY, not the WHAT
- Self-documenting code preferred

## Testing

### Manual Testing
```bash
# Build debug
make build

# Run (will show in menu bar)
.build/debug/SaaS-Costs

# Check menu bar - should see total cost
```

### Provider Testing
Test individual providers before integration:
```swift
// Temporarily in main.swift
let provider = OpenAIProvider()
let cost = try await provider.fetchCost()
print("OpenAI Cost: $\(cost)")
```

### Error Scenarios
Test with:
- Empty API key → `ProviderError.missingAPIKey`
- Invalid API key → `ProviderError.invalidResponse`
- Network timeout → async/await timeout
- Malformed JSON → decoding error

## Debugging

### Enable Verbose Output
```bash
# Build with debug symbols
swift build

# Check what providers are detected
# Add logging to ProviderFactory.swift
```

### Common Issues

**"API key not found"**
- Verify `.env.local` exists
- Check key name matches `ProcessInfo.processInfo.environment`
- Ensure no trailing spaces in .env.local

**"Invalid response"**
- Check HTTP status code (should be 200)
- Verify API endpoint URL
- Check request headers (Authorization format)

**"Decoding error"**
- Print raw response data
- Check JSON structure matches model
- Verify key names match with `CodingKeys`

## Building Release

### Create .app Bundle
1. Open `Package.swift` in Xcode
2. Create new macOS App target
3. Copy `Info.plist` to target
4. Add files from `Sources/` to target
5. Build → Product → Archive

### Code Signing
For distribution, sign with developer certificate:
```bash
codesign -s - .build/SaaS\ Costs\ Monitor.app
```

## Performance Considerations

- **Async/await** - Non-blocking provider calls
- **Actor isolation** - Thread-safe state
- **Error handling** - One provider failing doesn't affect others
- **Update interval** - Default 1 hour, customizable in AppConfig

## Dependencies

None! Uses only Swift stdlib and AppKit:
- `Foundation` - Date, URLSession, Codable
- `AppKit` - NSStatusItem, NSApplication

No external packages = faster builds, fewer vulnerabilities.

## Git Workflow

1. Create feature branch
2. Make changes (keep commits focused)
3. Run `make lint` before commit
4. Push and create PR
5. Validate tests pass in CI

Commit message format:
```
Brief summary of changes

- Bullet point 1
- Bullet point 2

Fixes #123 (if applicable)
```

import Foundation

struct ProviderSetup {
    let fetchers: [any CostFetcher]
    let unavailable: [ProviderResult]
}

enum ProviderCatalog {
    /// Providers whose keys may be present but that expose no spend API usable with those keys.
    private static let withoutCostAPI: [(name: String, key: String)] = [
        ("Google Gemini", "GEMINI_API_KEY"),
        ("Groq", "GROQ_API_KEY"),
        ("Cerebras", "CEREBRAS_API_KEY"),
        ("ElevenLabs", "ELEVEN_LABS_KEY"),
        ("Soniox", "SONIOX_API_KEY")
    ]

    static func setup(from env: [String: String]) -> ProviderSetup {
        func value(_ key: String) -> String? {
            guard let value = env[key], !value.isEmpty else {
                return nil
            }
            return value
        }

        var fetchers: [any CostFetcher] = []
        var unavailable: [ProviderResult] = []

        if let key = value("ANTHROPIC_ADMIN_KEY") {
            fetchers.append(AnthropicCostFetcher(adminKey: key))
        } else if value("ANTHROPIC_API_KEY") != nil {
            unavailable.append(ProviderResult(name: "Anthropic", status: .unavailable("Needs ANTHROPIC_ADMIN_KEY")))
        }

        if let key = value("OPENAI_ADMIN_KEY") {
            fetchers.append(OpenAICostFetcher(adminKey: key))
        } else if value("OPENAI_API_KEY") != nil {
            unavailable.append(ProviderResult(name: "OpenAI", status: .unavailable("Needs OPENAI_ADMIN_KEY")))
        }

        if let key = value("XAI_MANAGEMENT_KEY") {
            fetchers.append(XAICostFetcher(managementKey: key, teamID: value("XAI_TEAM_ID")))
        } else if value("GROK_API_KEY") != nil {
            unavailable.append(ProviderResult(name: "xAI", status: .unavailable("Needs XAI_MANAGEMENT_KEY")))
        }

        for provider in withoutCostAPI where value(provider.key) != nil {
            unavailable.append(ProviderResult(name: provider.name, status: .unavailable("No cost API")))
        }

        return ProviderSetup(fetchers: fetchers, unavailable: unavailable)
    }
}

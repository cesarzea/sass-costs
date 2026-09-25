import Foundation

struct ProviderSetup {
    let fetchers: [any CostFetcher]
    let unavailable: [ProviderResult]
}

enum ProviderCatalog {
    private struct SpecialKey {
        let name: String
        let regularKey: String
        let requiredKey: String
    }

    /// Providers whose regular key cannot read spend; the named key is required instead.
    private static let needsSpecialKey = [
        SpecialKey(name: "Anthropic", regularKey: "ANTHROPIC_API_KEY", requiredKey: "ANTHROPIC_ADMIN_KEY"),
        SpecialKey(name: "OpenAI", regularKey: "OPENAI_API_KEY", requiredKey: "OPENAI_ADMIN_KEY"),
        SpecialKey(name: "xAI", regularKey: "GROK_API_KEY", requiredKey: "XAI_MANAGEMENT_KEY")
    ]

    /// Providers whose keys may be present but that expose no spend API.
    private static let withoutCostAPI: [(name: String, key: String)] = [
        ("Google Gemini", "GEMINI_API_KEY"),
        ("Groq", "GROQ_API_KEY"),
        ("Cerebras", "CEREBRAS_API_KEY")
    ]

    static func setup(from env: [String: String]) -> ProviderSetup {
        let values = env.filter { !$0.value.isEmpty }
        return ProviderSetup(fetchers: fetchers(from: values), unavailable: unavailable(from: values))
    }

    private static func fetchers(from env: [String: String]) -> [any CostFetcher] {
        var fetchers: [any CostFetcher] = []
        if let key = env["ANTHROPIC_ADMIN_KEY"] {
            fetchers.append(AnthropicCostFetcher(adminKey: key))
        }
        if let key = env["OPENAI_ADMIN_KEY"] {
            fetchers.append(OpenAICostFetcher(adminKey: key))
        }
        if let key = env["XAI_MANAGEMENT_KEY"] {
            fetchers.append(XAICostFetcher(managementKey: key, teamID: env["XAI_TEAM_ID"]))
        }
        if let key = env["ELEVEN_LABS_KEY"] {
            fetchers.append(ElevenLabsCostFetcher(apiKey: key))
        }
        if let key = env["SONIOX_API_KEY"] {
            fetchers.append(SonioxCostFetcher(apiKey: key))
        }
        return fetchers
    }

    private static func unavailable(from env: [String: String]) -> [ProviderResult] {
        let missingKey = needsSpecialKey
            .filter { env[$0.regularKey] != nil && env[$0.requiredKey] == nil }
            .map { ProviderResult(name: $0.name, status: .unavailable("Needs \($0.requiredKey)")) }
        let noAPI = withoutCostAPI
            .filter { env[$0.key] != nil }
            .map { ProviderResult(name: $0.name, status: .unavailable("No cost API")) }
        return missingKey + noAPI
    }
}

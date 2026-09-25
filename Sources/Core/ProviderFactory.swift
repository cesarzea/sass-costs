import Foundation

struct ProviderFactory {
    private let env: [String: String]

    init(env: [String: String]? = nil) {
        self.env = env ?? EnvLoader.load()
    }

    func createAllProviders() -> [CostFetcher] {
        var providers: [CostFetcher] = []

        if env["ANTHROPIC_API_KEY"] != nil {
            providers.append(AnthropicProvider())
        }

        if env["OPENAI_API_KEY"] != nil {
            providers.append(OpenAIProvider())
        }

        if env["GEMINI_API_KEY"] != nil {
            providers.append(GeminiProvider())
        }

        if env["GROQ_API_KEY"] != nil {
            providers.append(GroqProvider())
        }

        if env["GROK_API_KEY"] != nil {
            providers.append(GrokProvider())
        }

        if env["CEREBRAS_API_KEY"] != nil {
            providers.append(CerebrasProvider())
        }

        if env["ELEVEN_LABS_KEY"] != nil {
            providers.append(ElevenLabsProvider())
        }

        if env["SONIOX_API_KEY"] != nil {
            providers.append(SonioxProvider())
        }

        return providers
    }
}

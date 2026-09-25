import Foundation

struct OpenAIProvider: CostFetcher {
    let providerName = "OpenAI"
    let apiKey: String?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }

    func fetchCost() async throws -> Double {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }

        // TODO: Implement OpenAI API billing fetch
        // https://platform.openai.com/account/billing/usage
        return 0.0
    }
}

import Foundation

struct GroqProvider: CostFetcher {
    let providerName = "Groq"
    let apiKey: String?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["GROQ_API_KEY"]
    }

    func fetchCost() async throws -> Double {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }

        // TODO: Implement Groq billing API
        return 0.0
    }
}

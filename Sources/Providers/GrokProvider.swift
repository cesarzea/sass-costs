import Foundation

struct GrokProvider: CostFetcher {
    let providerName = "Grok (xAI)"
    let apiKey: String?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["GROK_API_KEY"]
    }

    func fetchCost() async throws -> Double {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }

        // TODO: Implement xAI Grok billing API
        return 0.0
    }
}

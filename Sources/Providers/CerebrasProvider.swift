import Foundation

struct CerebrasProvider: CostFetcher {
    let providerName = "Cerebras"
    let apiKey: String?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["CEREBRAS_API_KEY"]
    }

    func fetchCost() async throws -> Double {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }

        // TODO: Implement Cerebras billing API
        return 0.0
    }
}

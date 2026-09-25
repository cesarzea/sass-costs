import Foundation

struct GeminiProvider: CostFetcher {
    let providerName = "Google Gemini"
    let apiKey: String?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
    }

    func fetchCost() async throws -> Double {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }

        // TODO: Implement Google Cloud Billing API fetch
        // Requires GCP project setup
        return 0.0
    }
}

import Foundation

struct AnthropicProvider: CostFetcher {
    let providerName = "Anthropic"
    let apiKey: String?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
    }

    func fetchCost() async throws -> Double {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }

        let url = URL(string: "https://api.anthropic.com/v1/usage")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProviderError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let usage = try decoder.decode(AnthropicUsage.self, from: data)
        return usage.totalCost
    }
}

private struct AnthropicUsage: Codable {
    let totalCost: Double
}

enum ProviderError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not found or empty"
        case .invalidResponse:
            return "Invalid response from provider"
        case .networkError(let message):
            return message
        }
    }
}

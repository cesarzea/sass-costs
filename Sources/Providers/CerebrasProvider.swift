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

        let url = URL(string: "https://api.cerebras.ai/v1/billing/usage")!

        var request = URLRequest(url: url)
        request.setValue("Authorization: Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProviderError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let usage = try decoder.decode(CerebrasUsage.self, from: data)
        return usage.totalCost
    }
}

private struct CerebrasUsage: Codable {
    let totalCost: Double

    enum CodingKeys: String, CodingKey {
        case totalCost = "total_cost"
    }
}

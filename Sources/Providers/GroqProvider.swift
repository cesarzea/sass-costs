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

        let url = URL(string: "https://api.groq.com/billing/usage")!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProviderError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let usage = try decoder.decode(GroqUsage.self, from: data)
        return usage.totalCost
    }
}

private struct GroqUsage: Codable {
    let totalCost: Double

    enum CodingKeys: String, CodingKey {
        case totalCost = "total_cost"
    }
}
}

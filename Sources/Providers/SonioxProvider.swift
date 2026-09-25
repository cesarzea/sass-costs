import Foundation

struct SonioxProvider: CostFetcher {
    let providerName = "Soniox"
    let apiKey: String?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["SONIOX_API_KEY"]
    }

    func fetchCost() async throws -> Double {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }

        let url = URL(string: "https://api.soniox.com/v1/billing")!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProviderError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let billing = try decoder.decode(SonioxBilling.self, from: data)
        return billing.totalCost
    }
}

private struct SonioxBilling: Codable {
    let totalCost: Double

    enum CodingKeys: String, CodingKey {
        case totalCost = "total_cost"
    }
}

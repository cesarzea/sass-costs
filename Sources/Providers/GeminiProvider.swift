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

        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        let startString = dateFormatter.string(from: startOfMonth)
        let endString = dateFormatter.string(from: now)

        let url = URL(string: "https://cloudbilling.googleapis.com/v1/billingAccounts?filter=displayName%3D%22default%22")!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProviderError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let billing = try decoder.decode(GeminiBilling.self, from: data)
        return billing.totalCost
    }
}

private struct GeminiBilling: Codable {
    let billingAccounts: [String]?

    var totalCost: Double {
        0.0
    }
}

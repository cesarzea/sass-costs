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

        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]

        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: now)

        let url = URL(string: "https://api.openai.com/v1/dashboard/billing/usage?start_date=\(startString)&end_date=\(endString)")!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProviderError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let usage = try decoder.decode(OpenAIUsage.self, from: data)
        return usage.totalUsage
    }
}

private struct OpenAIUsage: Codable {
    let totalUsage: Double

    enum CodingKeys: String, CodingKey {
        case totalUsage = "total_usage"
    }
}

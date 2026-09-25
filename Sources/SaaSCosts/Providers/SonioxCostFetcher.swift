import Foundation

/// Reads spend from the Soniox usage summary. Works with a regular project API key.
struct SonioxCostFetcher: CostFetcher {
    let name = "Soniox"
    let apiKey: String
    var transport: any HTTPTransport = URLSessionTransport()

    func cost(for period: BillingPeriod) async throws -> Double {
        let formatter = ISO8601DateFormatter()
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.soniox.com"
        components.path = "/v1/usage/summary"
        components.queryItems = [
            URLQueryItem(name: "start_time", value: formatter.string(from: period.start)),
            URLQueryItem(name: "end_time", value: formatter.string(from: period.end))
        ]

        let request = try URLRequest(components, headers: ["Authorization": "Bearer \(apiKey)"])
        let summary = try JSONDecoder().decode(SonioxUsageSummary.self, from: try await transport.send(request))
        return try summary.totalUSD()
    }
}

struct SonioxUsageSummary: Decodable {
    let total: SonioxUsageTotal

    func totalUSD() throws -> Double {
        guard let value = Double(total.totalCostUSD) else {
            let detail = "total_cost_usd: \(total.totalCostUSD)"
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: detail))
        }
        return value
    }
}

struct SonioxUsageTotal: Decodable {
    enum CodingKeys: String, CodingKey {
        case totalCostUSD = "total_cost_usd"
    }

    /// Decimal string in dollars, e.g. "0.5802470000".
    let totalCostUSD: String
}

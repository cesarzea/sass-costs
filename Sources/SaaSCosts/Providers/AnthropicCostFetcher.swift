import Foundation

/// Reads spend from the Anthropic Admin API cost report. Requires an Admin key (`sk-ant-admin...`).
struct AnthropicCostFetcher: CostFetcher {
    let name = "Anthropic"
    let adminKey: String
    var transport: any HTTPTransport = URLSessionTransport()

    func cost(for period: BillingPeriod) async throws -> Double {
        var total = 0.0
        var page: String?
        repeat {
            let data = try await transport.send(URLRequest(query(period: period, page: page), headers: headers))
            let report = try JSONDecoder().decode(AnthropicCostReport.self, from: data)
            total += try report.totalUSD()
            page = report.hasMore ? report.nextPage : nil
        } while page != nil
        return total
    }

    private var headers: [String: String] {
        ["x-api-key": adminKey, "anthropic-version": "2023-06-01"]
    }

    private func query(period: BillingPeriod, page: String?) -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.anthropic.com"
        components.path = "/v1/organizations/cost_report"
        components.queryItems = [
            URLQueryItem(name: "starting_at", value: ISO8601DateFormatter().string(from: period.start)),
            URLQueryItem(name: "bucket_width", value: "1d"),
            URLQueryItem(name: "limit", value: "31")
        ]
        if let page {
            components.queryItems?.append(URLQueryItem(name: "page", value: page))
        }
        return components
    }
}

struct AnthropicCostReport: Decodable {
    struct Bucket: Decodable {
        let results: [Item]
    }

    struct Item: Decodable {
        /// Decimal string in cents, e.g. "123.45" means $1.2345.
        let amount: String
    }

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }

    let data: [Bucket]
    let hasMore: Bool
    let nextPage: String?

    func totalUSD() throws -> Double {
        let cents = try data.flatMap(\.results).reduce(0.0) { sum, item in
            guard let value = Double(item.amount) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "amount: \(item.amount)"))
            }
            return sum + value
        }
        return cents / 100
    }
}

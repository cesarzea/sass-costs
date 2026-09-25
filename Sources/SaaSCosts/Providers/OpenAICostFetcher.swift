import Foundation

/// Reads spend from the OpenAI organization costs endpoint. Requires an Admin key.
struct OpenAICostFetcher: CostFetcher {
    let name = "OpenAI"
    let adminKey: String
    var transport: any HTTPTransport = URLSessionTransport()

    func cost(for period: BillingPeriod) async throws -> Double {
        var total = 0.0
        var page: String?
        repeat {
            let data = try await transport.send(URLRequest(query(period: period, page: page), headers: headers))
            let report = try JSONDecoder().decode(OpenAICostReport.self, from: data)
            total += report.totalUSD
            page = report.hasMore ? report.nextPage : nil
        } while page != nil
        return total
    }

    private var headers: [String: String] {
        ["Authorization": "Bearer \(adminKey)"]
    }

    private func query(period: BillingPeriod, page: String?) -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.openai.com"
        components.path = "/v1/organization/costs"
        components.queryItems = [
            URLQueryItem(name: "start_time", value: String(Int(period.start.timeIntervalSince1970))),
            URLQueryItem(name: "bucket_width", value: "1d"),
            URLQueryItem(name: "limit", value: "31")
        ]
        if let page {
            components.queryItems?.append(URLQueryItem(name: "page", value: page))
        }
        return components
    }
}

struct OpenAICostReport: Decodable {
    struct Bucket: Decodable {
        let results: [Item]
    }

    struct Item: Decodable {
        let amount: Amount
    }

    struct Amount: Decodable {
        let value: Double
    }

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }

    let data: [Bucket]
    let hasMore: Bool
    let nextPage: String?

    var totalUSD: Double {
        data.flatMap(\.results).reduce(0) { $0 + $1.amount.value }
    }
}

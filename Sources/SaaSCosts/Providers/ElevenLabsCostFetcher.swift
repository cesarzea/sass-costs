import Foundation

/// Reads usage cost from the ElevenLabs workspace analytics. Covers metered usage, not the plan fee.
struct ElevenLabsCostFetcher: CostFetcher {
    let name = "ElevenLabs"
    let apiKey: String
    var transport: any HTTPTransport = URLSessionTransport()

    func cost(for period: BillingPeriod) async throws -> Double {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.elevenlabs.io"
        components.path = "/v1/workspace/analytics/query/usage-by-product-over-time"

        let body = try JSONEncoder().encode(ElevenLabsUsageRequest(period: period))
        let request = try URLRequest(components, method: "POST", headers: [
            "xi-api-key": apiKey,
            "Content-Type": "application/json"
        ], body: body)

        let table = try JSONDecoder().decode(ElevenLabsUsageTable.self, from: try await transport.send(request))
        return try table.totalUSD()
    }
}

struct ElevenLabsUsageRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case endTime = "end_time"
        case intervalSeconds = "interval_seconds"
        case groupBy = "group_by"
    }

    let startTime: Int64
    let endTime: Int64
    let intervalSeconds = 86_400
    let groupBy = ["product_type"]

    init(period: BillingPeriod) {
        startTime = Int64(period.start.timeIntervalSince1970 * 1_000)
        endTime = Int64(period.end.timeIntervalSince1970 * 1_000)
    }
}

struct ElevenLabsUsageTable: Decodable {
    enum Cell: Decodable {
        case number(Double)
        case other

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self = (try? container.decode(Double.self)).map(Cell.number) ?? .other
        }
    }

    enum CodingKeys: String, CodingKey {
        case columns
        case units = "column_units"
        case rows
    }

    let columns: [String]
    let units: [String?]?
    let rows: [[Cell]]

    func totalUSD() throws -> Double {
        let index = columns.firstIndex(of: "total_cost")
        let unit = units.flatMap { units in index.flatMap { units.indices.contains($0) ? units[$0] : nil } }
        guard let index, unit == nil || unit == "usd" else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "No total_cost column in USD"))
        }
        return rows.reduce(0) { sum, row in
            guard case .number(let value) = row[safe: index] else {
                return sum
            }
            return sum + value
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

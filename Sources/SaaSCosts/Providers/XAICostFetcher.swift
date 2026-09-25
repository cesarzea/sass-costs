import Foundation

/// Reads spend from the xAI Management API. Requires a management key with BillingRead;
/// the team id is looked up from the key when not configured.
struct XAICostFetcher: CostFetcher {
    enum Failure: LocalizedError {
        case truncated

        var errorDescription: String? {
            "xAI returned a truncated usage report"
        }
    }

    let name = "xAI"
    let managementKey: String
    var teamID: String?
    var transport: any HTTPTransport = URLSessionTransport()

    func cost(for period: BillingPeriod) async throws -> Double {
        let team = try await resolvedTeamID()
        let body = try JSONEncoder().encode(XAIUsageRequest(period: period))
        let request = try URLRequest(endpoint("/v1/billing/teams/\(team)/usage"), method: "POST", headers: [
            "Authorization": "Bearer \(managementKey)",
            "Content-Type": "application/json"
        ], body: body)

        let report = try JSONDecoder().decode(XAIUsageReport.self, from: try await transport.send(request))
        guard report.limitReached != true else {
            throw Failure.truncated
        }
        return report.totalUSD
    }

    private func resolvedTeamID() async throws -> String {
        if let teamID {
            return teamID
        }
        let request = try URLRequest(
            endpoint("/auth/management-keys/validation"),
            headers: ["Authorization": "Bearer \(managementKey)"]
        )
        return try JSONDecoder().decode(XAIKeyInfo.self, from: try await transport.send(request)).teamId
    }

    private func endpoint(_ path: String) -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "management-api.x.ai"
        components.path = path
        return components
    }
}

struct XAIKeyInfo: Decodable {
    let teamId: String
}

struct XAIUsageRequest: Encodable {
    struct Analytics: Encodable {
        let timeRange: TimeRange
        let timeUnit = "TIME_UNIT_DAY"
        let values = [Value(name: "usd", aggregation: "AGGREGATION_SUM")]
        let groupBy: [String] = []
        let filters: [String] = []
    }

    struct TimeRange: Encodable {
        let startTime: String
        let endTime: String
        let timezone = "Etc/GMT"
    }

    struct Value: Encodable {
        let name: String
        let aggregation: String
    }

    let analyticsRequest: Analytics

    init(period: BillingPeriod) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        analyticsRequest = Analytics(timeRange: TimeRange(
            startTime: formatter.string(from: period.start),
            endTime: formatter.string(from: period.end)
        ))
    }
}

struct XAIUsageReport: Decodable {
    struct Series: Decodable {
        let dataPoints: [Point]
    }

    struct Point: Decodable {
        let values: [Double]
    }

    let timeSeries: [Series]
    let limitReached: Bool?

    var totalUSD: Double {
        timeSeries.flatMap(\.dataPoints).compactMap(\.values.first).reduce(0, +)
    }
}

@testable import SaaSCosts
import XCTest

final class XAICostFetcherTests: XCTestCase {
    private let period = BillingPeriod(
        start: Date(timeIntervalSince1970: 1_788_220_800),
        end: Date(timeIntervalSince1970: 1_790_000_000)
    )

    func testPostsUsageQueryAndSumsDollarValues() async throws {
        let transport = StubTransport(pages: [
            nil: """
            {"timeSeries": [
                {"group": ["grok-4"], "dataPoints": [
                    {"timestamp": "2026-09-01T00:00:00Z", "values": [0.75973725]},
                    {"timestamp": "2026-09-02T00:00:00Z", "values": [1.24026275]}]},
                {"group": ["image"], "dataPoints": [{"timestamp": "2026-09-02T00:00:00Z", "values": [3]}]}
             ],
             "limitReached": false}
            """
        ])
        let fetcher = XAICostFetcher(managementKey: "test", teamID: "team-1", transport: transport)

        let cost = try await fetcher.cost(for: period)

        XCTAssertEqual(cost, 5.0, accuracy: 0.000_1)
        let request = try XCTUnwrap(transport.requests.first)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://management-api.x.ai/v1/billing/teams/team-1/usage")

        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let analytics = try XCTUnwrap(json["analyticsRequest"] as? [String: Any])
        let range = try XCTUnwrap(analytics["timeRange"] as? [String: String])
        XCTAssertEqual(range["startTime"], "2026-09-01 00:00:00")
        XCTAssertEqual(range["endTime"], "2026-09-21 14:13:20")
        XCTAssertEqual(range["timezone"], "Etc/GMT")
    }

    func testLooksUpTeamFromKeyWhenNotConfigured() async throws {
        let transport = StubTransport { request in
            switch request.url?.path {
            case "/auth/management-keys/validation":
                return #"{"apiKeyId": "k", "teamId": "team-from-key", "acls": ["team-token:endpoint:BillingRead"]}"#
            case "/v1/billing/teams/team-from-key/usage":
                return #"{"timeSeries": [], "limitReached": false}"#
            default:
                return nil
            }
        }
        let fetcher = XAICostFetcher(managementKey: "test", transport: transport)

        let cost = try await fetcher.cost(for: period)

        XCTAssertEqual(cost, 0)
        XCTAssertEqual(transport.requests.map(\.httpMethod), ["GET", "POST"])
    }

    func testTruncatedReportIsAnError() async {
        let transport = StubTransport(pages: [nil: #"{"timeSeries": [], "limitReached": true}"#])
        let fetcher = XAICostFetcher(managementKey: "test", teamID: "team-1", transport: transport)

        do {
            _ = try await fetcher.cost(for: period)
            XCTFail("Expected truncated error")
        } catch {
            XCTAssertTrue(error is XAICostFetcher.Failure)
        }
    }
}

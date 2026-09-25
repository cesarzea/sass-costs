@testable import SaaSCosts
import XCTest

final class AnthropicCostFetcherTests: XCTestCase {
    private let period = BillingPeriod(
        start: Date(timeIntervalSince1970: 1_788_220_800),
        end: Date(timeIntervalSince1970: 1_790_000_000)
    )

    func testConvertsCentsToDollarsAcrossPages() async throws {
        let transport = StubTransport(pages: [
            nil: """
            {"data": [{"starting_at": "2026-09-01T00:00:00Z", "ending_at": "2026-09-02T00:00:00Z",
                       "results": [{"amount": "123.45", "currency": "USD"}, {"amount": "76.55", "currency": "USD"}]}],
             "has_more": true, "next_page": "p2"}
            """,
            "p2": """
            {"data": [{"starting_at": "2026-09-02T00:00:00Z", "ending_at": "2026-09-03T00:00:00Z",
                       "results": [{"amount": "50", "currency": "USD"}]},
                      {"starting_at": "2026-09-03T00:00:00Z", "ending_at": "2026-09-04T00:00:00Z", "results": []}],
             "has_more": false, "next_page": null}
            """
        ])
        let fetcher = AnthropicCostFetcher(adminKey: "test", transport: transport)

        let cost = try await fetcher.cost(for: period)

        XCTAssertEqual(cost, 2.50, accuracy: 0.000_1)
        XCTAssertEqual(transport.requests.count, 2)
        XCTAssertEqual(transport.requests.first?.url?.path, "/v1/organizations/cost_report")
        XCTAssertEqual(transport.requests.first?.query("starting_at"), "2026-09-01T00:00:00Z")
        XCTAssertEqual(transport.requests.first?.query("limit"), "31")
    }

    func testRejectsNonNumericAmount() async {
        let transport = StubTransport(pages: [
            nil: #"{"data": [{"results": [{"amount": "n/a"}]}], "has_more": false, "next_page": null}"#
        ])
        let fetcher = AnthropicCostFetcher(adminKey: "test", transport: transport)

        do {
            _ = try await fetcher.cost(for: period)
            XCTFail("Expected a decoding error")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
}

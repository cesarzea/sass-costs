@testable import SaaSCosts
import XCTest

final class OpenAICostFetcherTests: XCTestCase {
    func testSumsDollarAmountsAcrossPages() async throws {
        let transport = StubTransport(pages: [
            nil: """
            {"object": "page", "has_more": true, "next_page": "p2",
             "data": [{"object": "bucket", "start_time": 1788220800, "end_time": 1788307200,
                       "results": [{"object": "organization.costs.result",
                                    "amount": {"value": 0.06, "currency": "usd"}}]}]}
            """,
            "p2": """
            {"object": "page", "has_more": false, "next_page": null,
             "data": [{"object": "bucket", "start_time": 1788307200, "end_time": 1788393600,
                       "results": [{"object": "organization.costs.result",
                                    "amount": {"value": 1.5, "currency": "usd"}},
                                   {"object": "organization.costs.result",
                                    "amount": {"value": 2, "currency": "usd"}}]}]}
            """
        ])
        let fetcher = OpenAICostFetcher(adminKey: "test", transport: transport)
        let period = BillingPeriod(start: Date(timeIntervalSince1970: 1_788_220_800), end: Date())

        let cost = try await fetcher.cost(for: period)

        XCTAssertEqual(cost, 3.56, accuracy: 0.000_1)
        XCTAssertEqual(transport.requests.count, 2)
        XCTAssertEqual(transport.requests.first?.url?.path, "/v1/organization/costs")
        XCTAssertEqual(transport.requests.first?.query("start_time"), "1788220800")
        XCTAssertEqual(transport.requests.last?.query("page"), "p2")
    }
}

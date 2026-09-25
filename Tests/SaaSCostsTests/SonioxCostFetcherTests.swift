@testable import SaaSCosts
import XCTest

final class SonioxCostFetcherTests: XCTestCase {
    private let period = BillingPeriod(
        start: Date(timeIntervalSince1970: 1_788_220_800),
        end: Date(timeIntervalSince1970: 1_790_000_000)
    )

    func testReadsTotalCostAndSendsISORange() async throws {
        let transport = StubTransport(pages: [nil: """
            {"total": {"model": null, "days": ["2026-09-01", "2026-09-02"],
                       "total_cost_usd": "0.5802470000", "cost_usd": ["0.1415270000", "0.4387200000"]},
             "models": [{"model": "stt-rt-v5", "total_cost_usd": "0.5802470000"}]}
            """])
        let fetcher = SonioxCostFetcher(apiKey: "test", transport: transport)

        let cost = try await fetcher.cost(for: period)

        XCTAssertEqual(cost, 0.580_247, accuracy: 0.000_000_1)
        let request = try XCTUnwrap(transport.requests.first)
        XCTAssertEqual(request.url?.path, "/v1/usage/summary")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test")
        XCTAssertEqual(request.query("start_time"), "2026-09-01T00:00:00Z")
        XCTAssertEqual(request.query("end_time"), "2026-09-21T14:13:20Z")
    }

    func testRejectsNonNumericTotal() async {
        let transport = StubTransport(pages: [nil: #"{"total": {"total_cost_usd": "n/a"}}"#])
        let fetcher = SonioxCostFetcher(apiKey: "test", transport: transport)

        do {
            _ = try await fetcher.cost(for: period)
            XCTFail("Expected a decoding error")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
}

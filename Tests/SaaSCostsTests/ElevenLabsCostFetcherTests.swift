@testable import SaaSCosts
import XCTest

final class ElevenLabsCostFetcherTests: XCTestCase {
    private let period = BillingPeriod(
        start: Date(timeIntervalSince1970: 1_788_220_800),
        end: Date(timeIntervalSince1970: 1_790_000_000)
    )

    func testSumsTotalCostColumnAndSendsMillisecondRange() async throws {
        let transport = StubTransport(pages: [nil: """
            {"columns": ["product_type", "timestamp", "total_usage", "total_minutes", "total_cost", "usage_count"],
             "column_types": ["String", "DateTime", "Int", "Float", "Float", "Int"],
             "column_units": [null, null, "credits", "min", "usd", null],
             "rows": [["STT", "2026-09-01T00:00:00Z", 689, 12.71, 0.252, 3],
                      ["TTS", "2026-09-02T00:00:00Z", 51, 0.2, 0.0188, 1],
                      ["TTS", "2026-09-03T00:00:00Z", 0, 0, null, 0]]}
            """])
        let fetcher = ElevenLabsCostFetcher(apiKey: "test", transport: transport)

        let cost = try await fetcher.cost(for: period)

        XCTAssertEqual(cost, 0.2708, accuracy: 0.000_1)
        let request = try XCTUnwrap(transport.requests.first)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "xi-api-key"), "test")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(body["start_time"] as? Int, 1_788_220_800_000)
        XCTAssertEqual(body["end_time"] as? Int, 1_790_000_000_000)
    }

    func testRejectsCostColumnInOtherUnits() async {
        let transport = StubTransport(pages: [nil: """
            {"columns": ["total_cost"], "column_units": ["credits"], "rows": [[10]]}
            """])
        let fetcher = ElevenLabsCostFetcher(apiKey: "test", transport: transport)

        do {
            _ = try await fetcher.cost(for: period)
            XCTFail("Expected a unit error")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
}

@testable import SaaSCosts
import XCTest

private struct FixedFetcher: CostFetcher {
    let name: String
    let delay: UInt64
    let outcome: Result<Double, HTTPError>

    func cost(for period: BillingPeriod) async throws -> Double {
        try await Task.sleep(nanoseconds: delay)
        return try outcome.get()
    }
}

final class CostCollectorTests: XCTestCase {
    func testKeepsInputOrderAndReportsFailures() async {
        let fetchers: [any CostFetcher] = [
            FixedFetcher(name: "Slow", delay: 50_000_000, outcome: .success(1)),
            FixedFetcher(name: "Broken", delay: 0, outcome: .failure(.status(401))),
            FixedFetcher(name: "Fast", delay: 0, outcome: .success(2))
        ]

        let results = await CostCollector.collect(from: fetchers, period: .monthToDate())

        XCTAssertEqual(results, [
            ProviderResult(name: "Slow", status: .cost(1)),
            ProviderResult(name: "Broken", status: .failed("HTTP 401")),
            ProviderResult(name: "Fast", status: .cost(2))
        ])
    }
}

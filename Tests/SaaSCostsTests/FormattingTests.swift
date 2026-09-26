@testable import SaaSCosts
import XCTest

final class FormattingTests: XCTestCase {
    private let locale = Locale(identifier: "en_US")

    func testTotalSumsOnlyCostsAndFlagsFailures() {
        let results = [
            ProviderResult(name: "A", status: .cost(1.25)),
            ProviderResult(name: "B", status: .cost(2)),
            ProviderResult(name: "C", status: .unavailable("No cost API"))
        ]

        XCTAssertEqual(CostText.total(of: results, locale: locale), "$3.25")
        XCTAssertEqual(
            CostText.total(of: results + [ProviderResult(name: "D", status: .failed("HTTP 500"))], locale: locale),
            "$3.25 ⚠︎"
        )
        XCTAssertEqual(CostText.total(of: [], locale: locale), "–")
        let onlyFailure = [ProviderResult(name: "E", status: .failed("HTTP 401"))]
        XCTAssertEqual(CostText.total(of: onlyFailure, locale: locale), "⚠︎")
        XCTAssertTrue(CostText.hasFailures(onlyFailure))
        XCTAssertFalse(CostText.hasFailures(results))
    }

    func testMonthToDateStartsAtUTCMonthBoundary() {
        let now = Date(timeIntervalSince1970: 1_790_000_000) // 2026-09-21T14:13:20Z

        let period = BillingPeriod.monthToDate(now: now)

        XCTAssertEqual(period.start, Date(timeIntervalSince1970: 1_788_220_800)) // 2026-09-01T00:00:00Z
        XCTAssertEqual(period.end, now)
    }
}

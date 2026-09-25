import Foundation

protocol CostFetcher: Sendable {
    var name: String { get }

    /// Total spend in USD for the given period.
    func cost(for period: BillingPeriod) async throws -> Double
}

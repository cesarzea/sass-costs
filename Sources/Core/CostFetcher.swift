import Foundation

protocol CostFetcher {
    var providerName: String { get }
    var apiKey: String? { get }

    func fetchCost() async throws -> Double
}

struct ProviderCost {
    let name: String
    let cost: Double
    let currency: String = "USD"
    let lastUpdated: Date = Date()
}

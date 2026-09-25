import Foundation

enum CostCollector {
    /// Fetches all providers in parallel and returns results in the same order as `fetchers`.
    static func collect(from fetchers: [any CostFetcher], period: BillingPeriod) async -> [ProviderResult] {
        await withTaskGroup(of: (Int, ProviderResult).self) { group in
            for (index, fetcher) in fetchers.enumerated() {
                group.addTask {
                    (index, await result(of: fetcher, period: period))
                }
            }

            var results: [(Int, ProviderResult)] = []
            for await item in group {
                results.append(item)
            }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    private static func result(of fetcher: any CostFetcher, period: BillingPeriod) async -> ProviderResult {
        do {
            let cost = try await fetcher.cost(for: period)
            return ProviderResult(name: fetcher.name, status: .cost(cost))
        } catch {
            return ProviderResult(name: fetcher.name, status: .failed(error.localizedDescription))
        }
    }
}

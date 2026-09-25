import Foundation

actor CostCoordinator {
    private var providers: [CostFetcher] = []
    private var costs: [String: ProviderCost] = [:]

    init(providers: [CostFetcher]) {
        self.providers = providers
    }

    func addProvider(_ provider: CostFetcher) {
        providers.append(provider)
    }

    func fetchAllCosts() async {
        var results: [String: ProviderCost] = [:]

        await withTaskGroup(of: (String, ProviderCost)?.self) { group in
            for provider in providers {
                group.addTask {
                    do {
                        let cost = try await provider.fetchCost()
                        return (provider.providerName, ProviderCost(name: provider.providerName, cost: cost))
                    } catch {
                        print("Error fetching cost for \(provider.providerName): \(error)")
                        return nil
                    }
                }
            }

            for await result in group {
                if let (name, cost) = result {
                    results[name] = cost
                }
            }
        }

        costs = results
    }

    func getTotalCost() -> Double {
        return costs.values.reduce(0) { $0 + $1.cost }
    }

    func getCosts() -> [ProviderCost] {
        return costs.values.sorted { $0.cost > $1.cost }
    }
}

import Foundation

enum CostText {
    static func money(_ value: Double, locale: Locale = .current) -> String {
        value.formatted(.currency(code: "USD").locale(locale))
    }

    static func total(of results: [ProviderResult], locale: Locale = .current) -> String {
        let costs = results.compactMap { result -> Double? in
            if case .cost(let value) = result.status {
                return value
            }
            return nil
        }
        guard !costs.isEmpty else {
            return "–"
        }
        let hasFailures = results.contains { if case .failed = $0.status { return true } else { return false } }
        let total = money(costs.reduce(0, +), locale: locale)
        return hasFailures ? "\(total) ⚠︎" : total
    }

    static func detail(of status: ProviderResult.Status, locale: Locale = .current) -> String {
        switch status {
        case .cost(let value):
            return money(value, locale: locale)
        case .failed:
            return "Error"
        case .unavailable(let reason):
            return reason
        }
    }
}

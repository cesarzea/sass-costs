import Foundation

struct BillingPeriod: Equatable, Sendable {
    let start: Date
    let end: Date

    /// Providers bucket costs by UTC day, so the month boundary is computed in UTC.
    static func monthToDate(now: Date = Date()) -> BillingPeriod {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let components = calendar.dateComponents([.year, .month], from: now)
        let start = calendar.date(from: components) ?? now
        return BillingPeriod(start: start, end: now)
    }
}

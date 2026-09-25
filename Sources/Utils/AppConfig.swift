import Foundation

struct AppConfig {
    static let version = "1.0.0"
    static let appName = "SaaS Costs Monitor"
    static let bundleIdentifier = "com.cesarzea.sass-costs"

    static let defaultUpdateInterval: TimeInterval = 3600
    static let minimumUpdateInterval: TimeInterval = 300
    static let maximumUpdateInterval: TimeInterval = 86400

    enum UserDefaultsKeys {
        static let updateInterval = "com.cesarzea.sass-costs.updateInterval"
        static let lastUpdateTime = "com.cesarzea.sass-costs.lastUpdateTime"
        static let enabledProviders = "com.cesarzea.sass-costs.enabledProviders"
    }

    static func getUpdateInterval() -> TimeInterval {
        let defaults = UserDefaults.standard
        let interval = defaults.double(forKey: UserDefaultsKeys.updateInterval)

        if interval == 0 {
            return defaultUpdateInterval
        }

        return max(minimumUpdateInterval, min(interval, maximumUpdateInterval))
    }

    static func setUpdateInterval(_ interval: TimeInterval) {
        let clamped = max(minimumUpdateInterval, min(interval, maximumUpdateInterval))
        UserDefaults.standard.set(clamped, forKey: UserDefaultsKeys.updateInterval)
    }
}

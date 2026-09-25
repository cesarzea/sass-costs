import AppKit

@MainActor
final class StatusBarController: NSObject {
    private let refreshInterval: TimeInterval = 3600
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let setup: ProviderSetup
    private var period = BillingPeriod.monthToDate()
    private var results: [ProviderResult]
    private var lastUpdated: Date?
    private var isRefreshing = false
    private var timer: Timer?

    init(setup: ProviderSetup) {
        self.setup = setup
        self.results = setup.unavailable
        super.init()
        let icon = NSImage(systemSymbolName: "dollarsign.circle", accessibilityDescription: "SaaS costs")
        statusItem.button?.image = icon
        statusItem.button?.imagePosition = .imageLeading
        render()
    }

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    @objc
    private func refresh() {
        guard !isRefreshing else {
            return
        }
        isRefreshing = true
        period = BillingPeriod.monthToDate()
        render()

        Task {
            let fetched = await CostCollector.collect(from: setup.fetchers, period: period)
            results = fetched + setup.unavailable
            lastUpdated = Date()
            isRefreshing = false
            render()
        }
    }

    private func render() {
        statusItem.button?.title = isRefreshing && lastUpdated == nil ? "…" : CostText.total(of: results)
        statusItem.menu = MenuBuilder(
            results: results,
            period: period,
            lastUpdated: lastUpdated,
            isRefreshing: isRefreshing,
            refreshTarget: self,
            refreshAction: #selector(refresh)
        ).build()
    }
}

import AppKit

@MainActor
struct MenuBuilder {
    let results: [ProviderResult]
    let period: BillingPeriod
    let lastUpdated: Date?
    let isRefreshing: Bool
    let refreshTarget: AnyObject
    let refreshAction: Selector

    func build() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(label(headerText))
        menu.addItem(.separator())

        if results.isEmpty {
            menu.addItem(label("No provider keys found in ~/.config/sass-costs/.env"))
        }
        results.forEach { menu.addItem(row(for: $0)) }

        menu.addItem(.separator())
        menu.addItem(label(statusText))

        let refresh = NSMenuItem(title: "Refresh Now", action: refreshAction, keyEquivalent: "r")
        refresh.target = refreshTarget
        refresh.isEnabled = !isRefreshing
        menu.addItem(refresh)
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    private var headerText: String {
        var style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        style.timeZone = TimeZone(identifier: "UTC") ?? .current
        return "Spend since \(period.start.formatted(style)) (UTC)"
    }

    private var statusText: String {
        if isRefreshing {
            return "Updating…"
        }
        guard let lastUpdated else {
            return "Not updated yet"
        }
        return "Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))"
    }

    private func label(_ text: String) -> NSMenuItem {
        let item = NSMenuItem(title: text, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func row(for result: ProviderResult) -> NSMenuItem {
        let item = NSMenuItem(title: result.name, action: nil, keyEquivalent: "")
        let paragraph = NSMutableParagraphStyle()
        paragraph.tabStops = [NSTextTab(textAlignment: .right, location: 260)]

        let valueColor: NSColor
        switch result.status {
        case .cost:
            valueColor = .labelColor
        case .failed(let message):
            valueColor = .systemRed
            item.toolTip = message
        case .unavailable:
            valueColor = .secondaryLabelColor
        }

        let text = NSMutableAttributedString(
            string: "\(result.name)\t",
            attributes: [.paragraphStyle: paragraph, .font: NSFont.menuFont(ofSize: 0)]
        )
        let valueFont = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular)
        text.append(NSAttributedString(
            string: CostText.detail(of: result.status),
            attributes: [.foregroundColor: valueColor, .font: valueFont]
        ))
        item.attributedTitle = text
        return item
    }
}

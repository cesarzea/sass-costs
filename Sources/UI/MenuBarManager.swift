import AppKit
import SwiftUI

final class MenuBarManager: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let coordinator: CostCoordinator
    private var menuItems: [NSMenuItem] = []

    init(coordinator: CostCoordinator) {
        self.coordinator = coordinator
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        super.init()
        setupMenuBar()
    }

    private func setupMenuBar() {
        statusItem.button?.title = "$0.00"
        statusItem.button?.font = NSFont.systemFont(ofSize: 12, weight: .semibold)

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        updateMenu()
    }

    func updateMenu() {
        guard let menu = statusItem.menu else { return }

        menu.removeAllItems()
        menuItems.removeAll()

        let costs = Task {
            await coordinator.getCosts()
        }

        let totalCost = Task {
            await coordinator.getTotalCost()
        }

        updateStatusBarTitle()
        addCostItems(to: menu)
        addSeparator(to: menu)
        addFooterItems(to: menu)
    }

    private func updateStatusBarTitle() {
        Task {
            let total = await coordinator.getTotalCost()
            DispatchQueue.main.async { [weak self] in
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencyCode = "USD"
                self?.statusItem.button?.title = formatter.string(from: NSNumber(value: total)) ?? "$0.00"
            }
        }
    }

    private func addCostItems(to menu: NSMenu) {
        Task {
            let costs = await coordinator.getCosts()
            DispatchQueue.main.async { [weak self] in
                for cost in costs {
                    let item = NSMenuItem()
                    let title = "\(cost.name): $\(String(format: "%.2f", cost.cost))"
                    item.title = title
                    item.isEnabled = false
                    menu.addItem(item)
                    self?.menuItems.append(item)
                }
            }
        }
    }

    private func addSeparator(to menu: NSMenu) {
        menu.addItem(NSMenuItem.separator())
    }

    private func addFooterItems(to menu: NSMenu) {
        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(refresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
    }

    @objc private func refresh() {
        Task {
            await coordinator.fetchAllCosts()
            updateMenu()
        }
    }
}

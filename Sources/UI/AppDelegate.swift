import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?
    private var costUpdater: CostUpdater?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        let factory = ProviderFactory()
        let providers = factory.createAllProviders()

        let coordinator = CostCoordinator(providers: providers)

        menuBarManager = MenuBarManager(coordinator: coordinator)
        costUpdater = CostUpdater(coordinator: coordinator, updateInterval: 3600)

        costUpdater?.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldTerminate(
        _ sender: NSApplication,
        reply shouldTerminateReply: @escaping (NSApplication.TerminateReply) -> Void
    ) {
        costUpdater?.stop()
        shouldTerminateReply(.terminateNow)
    }
}

import AppKit

@main
@MainActor
enum SaaSCostsApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = StatusBarController(setup: ProviderCatalog.setup(from: EnvFile.load()))
        controller.start()
        self.controller = controller
    }
}

import Foundation

final class CostUpdater {
    private let coordinator: CostCoordinator
    private var timer: Timer?
    private let updateInterval: TimeInterval

    private(set) var isRunning: Bool = false

    init(coordinator: CostCoordinator, updateInterval: TimeInterval = 3600) {
        self.coordinator = coordinator
        self.updateInterval = updateInterval
    }

    func start() {
        guard !isRunning else { return }

        isRunning = true

        Task {
            await coordinator.fetchAllCosts()
        }

        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.coordinator.fetchAllCosts()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    deinit {
        stop()
    }
}

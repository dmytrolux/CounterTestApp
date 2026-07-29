import Network

@MainActor
protocol NetworkMonitoring: AnyObject {
    func start(statusDidChange: @escaping (Bool) -> Void)
    func stop()
}

@MainActor
final class NWPathNetworkMonitor: NetworkMonitoring {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.countertestapp.network-monitor")

    func start(statusDidChange: @escaping (Bool) -> Void) {
        monitor.pathUpdateHandler = { path in
            let isConnected = path.status == .satisfied
            DispatchQueue.main.async {
                statusDidChange(isConnected)
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}

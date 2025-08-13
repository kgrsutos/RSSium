import Foundation
import Network
import Combine

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = false
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    private func startMonitoring() {
        networkMonitor.start(queue: workerQueue)
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
    }
    
    
    var isWiFiConnected: Bool {
        isConnected && connectionType == .wifi
    }
    
    var isCellularConnected: Bool {
        isConnected && connectionType == .cellular
    }
}
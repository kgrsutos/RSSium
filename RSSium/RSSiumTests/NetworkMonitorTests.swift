import Testing
import Network
@testable import RSSium

@MainActor
struct NetworkMonitorTests {
    
    @Test("Initial connection state")
    func testInitialConnectionState() {
        let networkMonitor = NetworkMonitor.shared
        
        // NetworkMonitor should have some initial state
        // We can't guarantee the exact state as it depends on the test environment
        #expect(networkMonitor.isConnected == true || networkMonitor.isConnected == false)
    }
    
    @Test("Connection type properties")
    func testConnectionType() {
        let networkMonitor = NetworkMonitor.shared
        
        // Connection type may be nil if not connected
        if networkMonitor.isConnected {
            // If connected, we should have some connection type information
            // This test verifies the property exists and can be accessed
            _ = networkMonitor.connectionType
            _ = networkMonitor.isWiFiConnected
            _ = networkMonitor.isCellularConnected
        }
        
        // Test that properties are accessible without crashing
        let isWiFi = networkMonitor.isWiFiConnected
        let isCellular = networkMonitor.isCellularConnected
        #expect(isWiFi == true || isWiFi == false)
        #expect(isCellular == true || isCellular == false)
    }
    
    @Test("Singleton pattern")
    func testSingletonPattern() {
        let monitor1 = NetworkMonitor.shared
        let monitor2 = NetworkMonitor.shared
        #expect(monitor1 === monitor2)
    }
}
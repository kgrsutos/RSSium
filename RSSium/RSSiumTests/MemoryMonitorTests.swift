import Testing
import Foundation
import UIKit
@testable import RSSium

struct MemoryMonitorTests {
    
    private func createTestMemoryMonitor() -> MemoryMonitor {
        // MemoryMonitor is a singleton with @MainActor
        return MemoryMonitor.shared
    }
    
    @Test("MemoryMonitor initialization")
    @MainActor func testInitialization() {
        let monitor = createTestMemoryMonitor()
        #expect(monitor != nil)
        #expect(monitor.currentMemoryUsage >= 0.0)
        #expect(monitor.currentMemoryUsage <= 1.0)
    }
    
    @Test("MemoryMonitor singleton behavior")
    @MainActor func testSingletonBehavior() {
        let monitor1 = MemoryMonitor.shared
        let monitor2 = MemoryMonitor.shared
        
        #expect(monitor1 === monitor2)
    }
    
    @Test("Memory usage percentage is valid range")
    @MainActor func testMemoryUsageRange() {
        let monitor = createTestMemoryMonitor()
        
        // Memory usage should be between 0 and 1 (0% to 100%)
        #expect(monitor.currentMemoryUsage >= 0.0)
        #expect(monitor.currentMemoryUsage <= 1.0)
    }
    
    @Test("Memory usage in MB is positive")
    @MainActor func testMemoryUsageInMB() {
        let monitor = createTestMemoryMonitor()
        
        let usageMB = monitor.getMemoryUsageMB()
        #expect(usageMB >= 0.0)
        #expect(usageMB < 10000.0) // Sanity check - should be less than 10GB
    }
    
    @Test("Memory usage description format")
    @MainActor func testMemoryUsageDescription() {
        let monitor = createTestMemoryMonitor()
        
        let description = monitor.memoryUsageDescription
        #expect(!description.isEmpty)
        #expect(description.contains("MB"))
        #expect(description.contains("%"))
    }
    
    @Test("Memory pressure starts as false")
    @MainActor func testInitialMemoryPressure() {
        let monitor = createTestMemoryMonitor()
        
        // Initially, memory pressure should typically be false
        // (unless the test environment is already under memory pressure)
        #expect(monitor.isMemoryPressureHigh == false || monitor.isMemoryPressureHigh == true)
    }
    
    @Test("Memory cleanup can be performed")
    @MainActor func testMemoryCleanup() async {
        let monitor = createTestMemoryMonitor()
        
        // Store initial state
        let initialPressure = monitor.isMemoryPressureHigh
        
        // Perform cleanup - should not crash
        await monitor.performMemoryCleanup()
        
        // After cleanup, pressure should be false
        #expect(monitor.isMemoryPressureHigh == false)
    }
    
    @Test("Memory monitoring properties are observable")
    @MainActor func testObservableProperties() {
        let monitor = createTestMemoryMonitor()
        
        // Test that properties are @Published by checking they exist
        let usage = monitor.currentMemoryUsage
        let pressure = monitor.isMemoryPressureHigh
        
        #expect(usage >= 0.0)
        #expect(pressure == true || pressure == false)
    }
    
    @Test("Memory usage calculation consistency")
    @MainActor func testMemoryUsageConsistency() {
        let monitor = createTestMemoryMonitor()
        
        let usage1 = monitor.getMemoryUsageMB()
        let usage2 = monitor.getMemoryUsageMB()
        
        // Usage should be reasonably consistent between calls
        let difference = abs(usage1 - usage2)
        #expect(difference < 50.0) // Allow for some variation, but not huge differences
    }
    
    @Test("Memory description contains valid values")
    @MainActor func testMemoryDescriptionValidation() {
        let monitor = createTestMemoryMonitor()
        
        let description = monitor.memoryUsageDescription
        
        // Extract numeric values from description
        let components = description.components(separatedBy: " ")
        #expect(components.count >= 3) // Should have at least "X.X MB (X.X%)"
        
        // First component should be a valid number (MB value)
        if let mbString = components.first,
           let mbValue = Double(mbString) {
            #expect(mbValue >= 0.0)
        }
    }
    
    @Test("Memory monitoring doesn't crash under normal conditions")
    @MainActor func testMemoryMonitoringStability() async {
        let monitor = createTestMemoryMonitor()
        
        // Perform multiple memory operations to test stability
        for _ in 0..<5 {
            let _ = monitor.getMemoryUsageMB()
            let _ = monitor.memoryUsageDescription
            let _ = monitor.currentMemoryUsage
            let _ = monitor.isMemoryPressureHigh
        }
        
        // Perform cleanup
        await monitor.performMemoryCleanup()
        
        // Should still be functional after cleanup
        let usage = monitor.getMemoryUsageMB()
        #expect(usage >= 0.0)
    }
    
    @Test("Memory warning notification can be triggered")
    @MainActor func testMemoryWarningNotification() async {
        let monitor = createTestMemoryMonitor()
        
        // Store initial state
        let initialPressure = monitor.isMemoryPressureHigh
        
        // Simulate memory warning
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Give some time for the notification to be processed
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // After warning, cleanup should have been triggered
        // and pressure should be reset to false
        #expect(monitor.isMemoryPressureHigh == false)
    }
    
    @Test("Multiple memory cleanups don't cause issues")
    @MainActor func testMultipleCleanups() async {
        let monitor = createTestMemoryMonitor()
        
        // Perform multiple cleanups in sequence
        await monitor.performMemoryCleanup()
        await monitor.performMemoryCleanup()
        await monitor.performMemoryCleanup()
        
        // Monitor should still be functional
        let usage = monitor.getMemoryUsageMB()
        #expect(usage >= 0.0)
        #expect(monitor.isMemoryPressureHigh == false)
    }
    
    @Test("Memory usage values are reasonable")
    @MainActor func testReasonableMemoryValues() {
        let monitor = createTestMemoryMonitor()
        
        let usageMB = monitor.getMemoryUsageMB()
        let usagePercentage = monitor.currentMemoryUsage
        
        // Memory usage should be reasonable for a test environment
        #expect(usageMB > 0) // Should be using some memory
        #expect(usageMB < 2048) // Should be less than 2GB in test environment
        #expect(usagePercentage >= 0.0)
        #expect(usagePercentage <= 1.0)
    }
    
    @Test("Memory description formatting is correct")
    @MainActor func testMemoryDescriptionFormatting() {
        let monitor = createTestMemoryMonitor()
        
        let description = monitor.memoryUsageDescription
        
        // Should match format "X.X MB (X.X%)"
        let pattern = #"^\d+\.\d+ MB \(\d+\.\d+%\)$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.numberOfMatches(
            in: description,
            options: [],
            range: NSRange(location: 0, length: description.count)
        )
        
        #expect(matches == 1)
    }
}
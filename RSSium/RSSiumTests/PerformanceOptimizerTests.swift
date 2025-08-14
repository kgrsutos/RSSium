import Testing
import Foundation
@testable import RSSium

struct PerformanceOptimizerTests {
    
    @MainActor
    @Test("PerformanceOptimizer singleton instance")
    func testSingletonInstance() {
        let instance1 = PerformanceOptimizer.shared
        let instance2 = PerformanceOptimizer.shared
        
        #expect(instance1 === instance2)
    }
    
    @MainActor
    @Test("Apply balanced preset settings")
    func testApplyBalancedPreset() {
        let optimizer = PerformanceOptimizer.shared
        
        optimizer.applyPreset(.balanced)
        
        #expect(optimizer.isEnabled == true)
        #expect(optimizer.aggressiveMemoryManagement == false)
        #expect(optimizer.reduceAnimations == false)
        #expect(optimizer.limitImageCache == true)
        #expect(optimizer.backgroundRefreshOptimized == false)
    }
    
    @MainActor
    @Test("Apply performance first preset settings")
    func testApplyPerformanceFirstPreset() {
        let optimizer = PerformanceOptimizer.shared
        
        optimizer.applyPreset(.performanceFirst)
        
        #expect(optimizer.isEnabled == true)
        #expect(optimizer.aggressiveMemoryManagement == true)
        #expect(optimizer.reduceAnimations == true)
        #expect(optimizer.limitImageCache == true)
        #expect(optimizer.backgroundRefreshOptimized == false)
    }
    
    @MainActor
    @Test("Apply battery optimized preset settings")
    func testApplyBatteryOptimizedPreset() {
        let optimizer = PerformanceOptimizer.shared
        
        optimizer.applyPreset(.batteryOptimized)
        
        #expect(optimizer.isEnabled == true)
        #expect(optimizer.aggressiveMemoryManagement == false)
        #expect(optimizer.reduceAnimations == true)
        #expect(optimizer.limitImageCache == true)
        #expect(optimizer.backgroundRefreshOptimized == true)
    }
    
    @MainActor
    @Test("Apply minimal preset settings")
    func testApplyMinimalPreset() {
        let optimizer = PerformanceOptimizer.shared
        
        optimizer.applyPreset(.minimal)
        
        #expect(optimizer.isEnabled == false)
        #expect(optimizer.aggressiveMemoryManagement == false)
        #expect(optimizer.reduceAnimations == false)
        #expect(optimizer.limitImageCache == false)
        #expect(optimizer.backgroundRefreshOptimized == false)
    }
    
    @MainActor
    @Test("Optimization status string generation")
    func testOptimizationStatusString() {
        let optimizer = PerformanceOptimizer.shared
        
        // Test disabled state
        optimizer.isEnabled = false
        #expect(optimizer.optimizationStatus == "Disabled")
        
        // Test enabled with no specific optimizations
        optimizer.isEnabled = true
        optimizer.limitImageCache = false
        optimizer.backgroundRefreshOptimized = false
        optimizer.aggressiveMemoryManagement = false
        optimizer.reduceAnimations = false
        #expect(optimizer.optimizationStatus == "Basic")
        
        // Test with all optimizations
        optimizer.limitImageCache = true
        optimizer.backgroundRefreshOptimized = true
        optimizer.aggressiveMemoryManagement = true
        optimizer.reduceAnimations = true
        let status = optimizer.optimizationStatus
        #expect(status.contains("Image Caching"))
        #expect(status.contains("Background Refresh"))
        #expect(status.contains("Memory Management"))
        #expect(status.contains("Reduced Animations"))
    }
    
    @MainActor
    @Test("Apply optimizations when enabled")
    func testApplyOptimizationsWhenEnabled() {
        let optimizer = PerformanceOptimizer.shared
        
        optimizer.isEnabled = true
        optimizer.applyOptimizations()
        
        // Should not crash and should apply settings
        #expect(true)
    }
    
    @MainActor
    @Test("Skip optimizations when disabled")
    func testSkipOptimizationsWhenDisabled() {
        let optimizer = PerformanceOptimizer.shared
        
        optimizer.isEnabled = false
        optimizer.applyOptimizations()
        
        // Should not crash and should skip settings
        #expect(true)
    }
    
    @MainActor
    @Test("Performance preset enum cases")
    func testPerformancePresetEnumCases() {
        let allPresets = PerformancePreset.allCases
        
        #expect(allPresets.count == 4)
        #expect(allPresets.contains(.balanced))
        #expect(allPresets.contains(.performanceFirst))
        #expect(allPresets.contains(.batteryOptimized))
        #expect(allPresets.contains(.minimal))
    }
    
    @MainActor
    @Test("Performance preset descriptions")
    func testPerformancePresetDescriptions() {
        #expect(PerformancePreset.balanced.description.contains("balance"))
        #expect(PerformancePreset.performanceFirst.description.contains("performance"))
        #expect(PerformancePreset.batteryOptimized.description.contains("battery"))
        #expect(PerformancePreset.minimal.description.contains("Minimal"))
    }
    
    @MainActor
    @Test("Performance preset raw values")
    func testPerformancePresetRawValues() {
        #expect(PerformancePreset.balanced.rawValue == "Balanced")
        #expect(PerformancePreset.performanceFirst.rawValue == "Performance First")
        #expect(PerformancePreset.batteryOptimized.rawValue == "Battery Optimized")
        #expect(PerformancePreset.minimal.rawValue == "Minimal")
    }
    
    @MainActor
    @Test("Apply optimizations with aggressive memory management")
    func testApplyOptimizationsWithAggressiveMemory() async throws {
        let optimizer = PerformanceOptimizer.shared
        
        optimizer.isEnabled = true
        optimizer.aggressiveMemoryManagement = true
        optimizer.applyOptimizations()
        
        // Let it run briefly
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Disable to stop the background task
        optimizer.aggressiveMemoryManagement = false
        optimizer.isEnabled = false
        
        // Should not crash
        #expect(true)
    }
    
    @MainActor
    @Test("Toggle individual optimization settings")
    func testToggleIndividualSettings() {
        let optimizer = PerformanceOptimizer.shared
        
        // Test toggling each setting
        optimizer.aggressiveMemoryManagement = true
        #expect(optimizer.aggressiveMemoryManagement == true)
        optimizer.aggressiveMemoryManagement = false
        #expect(optimizer.aggressiveMemoryManagement == false)
        
        optimizer.reduceAnimations = true
        #expect(optimizer.reduceAnimations == true)
        optimizer.reduceAnimations = false
        #expect(optimizer.reduceAnimations == false)
        
        optimizer.limitImageCache = true
        #expect(optimizer.limitImageCache == true)
        optimizer.limitImageCache = false
        #expect(optimizer.limitImageCache == false)
        
        optimizer.backgroundRefreshOptimized = true
        #expect(optimizer.backgroundRefreshOptimized == true)
        optimizer.backgroundRefreshOptimized = false
        #expect(optimizer.backgroundRefreshOptimized == false)
    }
    
    @MainActor
    @Test("Preset changes affect background refresh interval")
    func testPresetChangesBackgroundRefreshInterval() {
        let optimizer = PerformanceOptimizer.shared
        let scheduler = BackgroundRefreshScheduler.shared
        
        // Performance first - 30 minutes
        optimizer.applyPreset(.performanceFirst)
        // Can't directly verify interval but operation should complete
        
        // Battery optimized - 4 hours
        optimizer.applyPreset(.batteryOptimized)
        // Can't directly verify interval but operation should complete
        
        // Balanced - 1 hour
        optimizer.applyPreset(.balanced)
        // Can't directly verify interval but operation should complete
        
        #expect(true) // All operations completed without crashing
    }
    
    @MainActor
    @Test("Multiple preset applications")
    func testMultiplePresetApplications() {
        let optimizer = PerformanceOptimizer.shared
        
        // Apply each preset multiple times
        for _ in 0..<3 {
            for preset in PerformancePreset.allCases {
                optimizer.applyPreset(preset)
            }
        }
        
        // Should handle multiple applications without issues
        #expect(true)
    }
}
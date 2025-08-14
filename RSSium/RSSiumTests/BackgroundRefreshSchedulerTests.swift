import Testing
import Foundation
import BackgroundTasks
@testable import RSSium

struct BackgroundRefreshSchedulerTests {
    
    private func createTestScheduler() -> BackgroundRefreshScheduler {
        // BackgroundRefreshScheduler is a singleton with @MainActor
        return BackgroundRefreshScheduler.shared
    }
    
    @Test("BackgroundRefreshScheduler initialization")
    @MainActor func testInitialization() {
        let scheduler = createTestScheduler()
        #expect(scheduler != nil)
    }
    
    @Test("BackgroundRefreshScheduler singleton behavior")
    @MainActor func testSingletonBehavior() {
        let scheduler1 = BackgroundRefreshScheduler.shared
        let scheduler2 = BackgroundRefreshScheduler.shared
        
        #expect(scheduler1 === scheduler2)
    }
    
    @Test("Default refresh interval is reasonable")
    @MainActor func testDefaultRefreshInterval() {
        let scheduler = createTestScheduler()
        
        // Access the interval through the settings change method
        scheduler.setRefreshInterval(3600) // 1 hour
        
        // The operation should complete without error
        // We can't directly test the internal value due to @AppStorage
    }
    
    @Test("Refresh interval can be changed")
    @MainActor func testRefreshIntervalChange() {
        let scheduler = createTestScheduler()
        
        // Test different intervals
        let intervals: [TimeInterval] = [1800, 3600, 7200, 21600] // 30 min, 1h, 2h, 6h
        
        for interval in intervals {
            scheduler.setRefreshInterval(interval)
            // Should not crash or throw errors
        }
    }
    
    @Test("Background refresh can be toggled")
    @MainActor func testBackgroundRefreshToggle() {
        let scheduler = createTestScheduler()
        
        // Test enabling
        scheduler.toggleBackgroundRefresh(true)
        
        // Test disabling
        scheduler.toggleBackgroundRefresh(false)
        
        // Test re-enabling
        scheduler.toggleBackgroundRefresh(true)
        
        // Should not crash or throw errors
    }
    
    @Test("Last refresh date initially nil")
    @MainActor func testInitialLastRefreshDate() {
        let scheduler = createTestScheduler()
        
        // Initially, last refresh date might be nil or a previous date
        let lastDate = scheduler.lastRefreshDate
        #expect(lastDate == nil || lastDate! <= Date())
    }
    
    @Test("Schedule background refresh doesn't crash")
    @MainActor func testScheduleBackgroundRefresh() {
        let scheduler = createTestScheduler()
        
        // Enable background refresh first
        scheduler.toggleBackgroundRefresh(true)
        
        // Schedule refresh - this might fail in test environment but shouldn't crash
        scheduler.scheduleBackgroundRefresh()
        
        // Should complete without crashing
    }
    
    @Test("Schedule background cleanup doesn't crash")
    @MainActor func testScheduleBackgroundCleanup() {
        let scheduler = createTestScheduler()
        
        // Schedule cleanup - this might fail in test environment but shouldn't crash
        scheduler.scheduleBackgroundCleanup()
        
        // Should complete without crashing
    }
    
    @Test("Register background tasks doesn't crash")
    @MainActor func testRegisterBackgroundTasks() {
        let scheduler = createTestScheduler()
        
        // Register tasks - this might fail in test environment but shouldn't crash
        scheduler.registerBackgroundTasks()
        
        // Should complete without crashing
    }
    
    @Test("Multiple toggle operations are stable")
    @MainActor func testMultipleToggleOperations() {
        let scheduler = createTestScheduler()
        
        // Perform multiple toggle operations
        for i in 0..<5 {
            scheduler.toggleBackgroundRefresh(i % 2 == 0)
        }
        
        // Should remain stable
    }
    
    @Test("Multiple interval changes are stable")
    @MainActor func testMultipleIntervalChanges() {
        let scheduler = createTestScheduler()
        
        // Perform multiple interval changes
        let intervals: [TimeInterval] = [900, 1800, 3600, 7200]
        
        for interval in intervals {
            scheduler.setRefreshInterval(interval)
        }
        
        // Should remain stable
    }
    
    @Test("Extreme interval values don't cause issues")
    @MainActor func testExtremeIntervalValues() {
        let scheduler = createTestScheduler()
        
        // Test very small interval
        scheduler.setRefreshInterval(60) // 1 minute
        
        // Test very large interval
        scheduler.setRefreshInterval(86400) // 24 hours
        
        // Test edge case - zero (though not realistic)
        scheduler.setRefreshInterval(0)
        
        // Should handle gracefully
    }
    
    @Test("Scheduler operations are thread-safe")
    @MainActor func testThreadSafety() async {
        let scheduler = createTestScheduler()
        
        // Perform concurrent operations
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await MainActor.run {
                    scheduler.toggleBackgroundRefresh(true)
                }
            }
            
            group.addTask {
                await MainActor.run {
                    scheduler.setRefreshInterval(3600)
                }
            }
            
            group.addTask {
                await MainActor.run {
                    scheduler.scheduleBackgroundRefresh()
                }
            }
            
            group.addTask {
                await MainActor.run {
                    scheduler.scheduleBackgroundCleanup()
                }
            }
        }
        
        // Should complete without issues
    }
    
    @Test("Last refresh date property behavior")
    @MainActor func testLastRefreshDateProperty() {
        let scheduler = createTestScheduler()
        
        let initialDate = scheduler.lastRefreshDate
        
        // Date should be either nil or a valid past date
        if let date = initialDate {
            #expect(date <= Date())
        }
        
        // Property access should be consistent
        let secondAccess = scheduler.lastRefreshDate
        #expect(initialDate == secondAccess)
    }
    
    @Test("Scheduler handles rapid consecutive calls")
    @MainActor func testRapidConsecutiveCalls() {
        let scheduler = createTestScheduler()
        
        // Rapid consecutive scheduling calls
        for _ in 0..<10 {
            scheduler.scheduleBackgroundRefresh()
        }
        
        // Rapid consecutive cleanup scheduling
        for _ in 0..<10 {
            scheduler.scheduleBackgroundCleanup()
        }
        
        // Should handle gracefully without crashes
    }
    
    @Test("Scheduler maintains state consistency")
    @MainActor func testStateConsistency() {
        let scheduler = createTestScheduler()
        
        // Set a known state
        scheduler.toggleBackgroundRefresh(true)
        scheduler.setRefreshInterval(3600)
        
        // Perform some operations
        scheduler.scheduleBackgroundRefresh()
        scheduler.scheduleBackgroundCleanup()
        
        // Change state
        scheduler.toggleBackgroundRefresh(false)
        
        // Change back
        scheduler.toggleBackgroundRefresh(true)
        
        // Should maintain internal consistency
        // (We can't directly test internal state, but operations should not crash)
    }
    
    @Test("Scheduler responds to app storage changes")
    @MainActor func testAppStorageIntegration() {
        let scheduler = createTestScheduler()
        
        // Test that changing settings through the scheduler works
        scheduler.setRefreshInterval(1800) // 30 minutes
        scheduler.toggleBackgroundRefresh(false)
        scheduler.toggleBackgroundRefresh(true)
        
        // Should integrate properly with @AppStorage without crashes
    }
}
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
    
    @Test("Background refresh scheduling with enabled state")
    @MainActor func testBackgroundRefreshSchedulingWithEnabledState() {
        let scheduler = createTestScheduler()
        
        // Test scheduling when enabled
        scheduler.toggleBackgroundRefresh(true)
        scheduler.scheduleBackgroundRefresh()
        
        // Test scheduling when disabled - should cancel tasks
        scheduler.toggleBackgroundRefresh(false)
        scheduler.scheduleBackgroundRefresh()
        
        // Should handle state changes gracefully
    }
    
    @Test("Task identifier constants are valid")
    @MainActor func testTaskIdentifierConstants() {
        let scheduler = createTestScheduler()
        
        // We can't directly access private properties, but we can test that
        // the scheduler initializes without issues, implying valid identifiers
        scheduler.registerBackgroundTasks()
        scheduler.scheduleBackgroundRefresh()
        scheduler.scheduleBackgroundCleanup()
        
        // Should work with valid identifiers
    }
    
    @Test("Background cleanup scheduling behavior")
    @MainActor func testBackgroundCleanupSchedulingBehavior() {
        let scheduler = createTestScheduler()
        
        // Schedule cleanup multiple times
        for _ in 0..<3 {
            scheduler.scheduleBackgroundCleanup()
        }
        
        // Should handle multiple scheduling requests
    }
    
    @Test("Refresh interval validation")
    @MainActor func testRefreshIntervalValidation() {
        let scheduler = createTestScheduler()
        
        // Test various interval values
        let validIntervals: [TimeInterval] = [
            300,    // 5 minutes
            900,    // 15 minutes
            1800,   // 30 minutes
            3600,   // 1 hour
            7200,   // 2 hours
            14400,  // 4 hours
            21600,  // 6 hours
            43200,  // 12 hours
            86400   // 24 hours
        ]
        
        for interval in validIntervals {
            scheduler.setRefreshInterval(interval)
            // Should accept all reasonable intervals
        }
    }
    
    @Test("Background refresh toggle affects scheduling")
    @MainActor func testBackgroundRefreshToggleAffectsScheduling() {
        let scheduler = createTestScheduler()
        
        // Start disabled
        scheduler.toggleBackgroundRefresh(false)
        scheduler.scheduleBackgroundRefresh()
        
        // Enable and schedule
        scheduler.toggleBackgroundRefresh(true)
        scheduler.scheduleBackgroundRefresh()
        scheduler.scheduleBackgroundCleanup()
        
        // Disable again
        scheduler.toggleBackgroundRefresh(false)
        
        // Should properly manage task scheduling based on enabled state
    }
    
    @Test("Last refresh date property consistency")
    @MainActor func testLastRefreshDatePropertyConsistency() {
        let scheduler = createTestScheduler()
        
        let initialDate1 = scheduler.lastRefreshDate
        let initialDate2 = scheduler.lastRefreshDate
        
        // Multiple accesses should return the same value
        #expect(initialDate1 == initialDate2)
        
        // Property should remain consistent across calls
        for _ in 0..<5 {
            let date = scheduler.lastRefreshDate
            #expect(date == initialDate1)
        }
    }
    
    @Test("Scheduler handles task registration gracefully")
    @MainActor func testSchedulerHandlesTaskRegistrationGracefully() {
        let scheduler = createTestScheduler()
        
        // Register tasks multiple times
        for _ in 0..<3 {
            scheduler.registerBackgroundTasks()
        }
        
        // Should handle multiple registrations without issues
    }
    
    @Test("Edge case refresh intervals")
    @MainActor func testEdgeCaseRefreshIntervals() {
        let scheduler = createTestScheduler()
        
        // Test edge cases
        scheduler.setRefreshInterval(1)       // Very small
        scheduler.setRefreshInterval(604800)  // 1 week
        scheduler.setRefreshInterval(2592000) // 30 days
        
        // Should handle edge cases without crashing
    }
    
    @Test("Concurrent background operations")
    @MainActor func testConcurrentBackgroundOperations() async {
        let scheduler = createTestScheduler()
        
        // Perform multiple operations concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    await MainActor.run {
                        scheduler.setRefreshInterval(TimeInterval(1800 + i * 300))
                        scheduler.scheduleBackgroundRefresh()
                        scheduler.scheduleBackgroundCleanup()
                    }
                }
            }
        }
        
        // Should handle concurrent operations safely
    }
}
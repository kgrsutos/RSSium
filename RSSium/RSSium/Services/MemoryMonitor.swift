import Foundation
import SwiftUI

@MainActor
class MemoryMonitor: ObservableObject {
    static let shared = MemoryMonitor()
    
    @Published var currentMemoryUsage: Double = 0.0
    @Published var isMemoryPressureHigh = false
    
    // Configurable memory thresholds
    struct MemoryThresholds {
        let warningThreshold: Double
        let cleanupThreshold: Double
        
        static let `default` = MemoryThresholds(
            warningThreshold: 0.8,  // 80% of available memory
            cleanupThreshold: 0.9   // 90% of available memory
        )
        
        static let conservative = MemoryThresholds(
            warningThreshold: 0.7,  // 70% of available memory
            cleanupThreshold: 0.8   // 80% of available memory
        )
        
        static let aggressive = MemoryThresholds(
            warningThreshold: 0.9,  // 90% of available memory
            cleanupThreshold: 0.95  // 95% of available memory
        )
    }
    
    private var thresholds: MemoryThresholds
    private var timer: Timer?
    
    private init(thresholds: MemoryThresholds = .default) {
        self.thresholds = thresholds
        startMonitoring()
        setupMemoryPressureNotifications()
    }
    
    // Allow updating thresholds at runtime
    func updateThresholds(_ newThresholds: MemoryThresholds) {
        self.thresholds = newThresholds
    }
    
    // Get current thresholds
    var currentThresholds: MemoryThresholds {
        return thresholds
    }
    
    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMemoryUsage()
            }
        }
    }
    
    private func setupMemoryPressureNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func didReceiveMemoryWarning() {
        Task { @MainActor in
            isMemoryPressureHigh = true
            await performMemoryCleanup()
        }
    }
    
    private func updateMemoryUsage() {
        let usage = getMemoryUsage()
        currentMemoryUsage = usage
        
        if usage > thresholds.cleanupThreshold {
            Task {
                await performMemoryCleanup()
            }
        } else if usage > thresholds.warningThreshold {
            isMemoryPressureHigh = true
        } else {
            isMemoryPressureHigh = false
        }
    }
    
    // MARK: - Memory Calculation
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size)
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
            return usedMemory / totalMemory
        }
        
        return 0.0
    }
    
    // MARK: - Memory Cleanup
    
    func performMemoryCleanup() async {
        // Clean up Core Data contexts
        PersistenceController.shared.optimizeMemoryUsage()
        PersistenceController.shared.cleanupBackgroundContexts()
        
        // Clean up image cache
        await ImageCacheService.shared.clearCache()
        
        // Force garbage collection
        autoreleasepool {
            // This helps ensure that any autoreleased objects are cleaned up
        }
        
        await MainActor.run {
            isMemoryPressureHigh = false
        }
    }
    
    // MARK: - Public Interface
    
    func getMemoryUsageMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024) // Convert to MB
        }
        
        return 0.0
    }
    
    var memoryUsageDescription: String {
        let usageMB = getMemoryUsageMB()
        let percentage = currentMemoryUsage * 100
        return String(format: "%.1f MB (%.1f%%)", usageMB, percentage)
    }
}
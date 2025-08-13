import Foundation
import SwiftUI

@MainActor
class PerformanceOptimizer: ObservableObject {
    static let shared = PerformanceOptimizer()
    
    @AppStorage("performanceOptimizationsEnabled") var isEnabled = true
    @AppStorage("aggressiveMemoryManagement") var aggressiveMemoryManagement = false
    @AppStorage("reduceAnimations") var reduceAnimations = false
    @AppStorage("limitImageCache") var limitImageCache = true
    @AppStorage("backgroundRefreshOptimized") var backgroundRefreshOptimized = true
    
    private init() {}
    
    // MARK: - Optimization Settings
    
    func applyOptimizations() {
        if isEnabled {
            configureImageCache()
            configureBackgroundRefresh()
            
            if aggressiveMemoryManagement {
                enableAggressiveMemoryManagement()
            }
        }
    }
    
    private func configureImageCache() {
        if limitImageCache {
            // Reduce image cache size for better memory management
            let cache = ImageCacheService.shared
            // The cache is already configured with reasonable limits in the service
        }
    }
    
    private func configureBackgroundRefresh() {
        if backgroundRefreshOptimized {
            // Use longer intervals to preserve battery
            BackgroundRefreshScheduler.shared.setRefreshInterval(7200) // 2 hours instead of 1
        }
    }
    
    private func enableAggressiveMemoryManagement() {
        // Trigger more frequent memory cleanup
        Task {
            while isEnabled && aggressiveMemoryManagement {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                await MemoryMonitor.shared.performMemoryCleanup()
            }
        }
    }
    
    // MARK: - Performance Metrics
    
    var optimizationStatus: String {
        guard isEnabled else { return "Disabled" }
        
        var optimizations: [String] = []
        
        if limitImageCache { optimizations.append("Image Caching") }
        if backgroundRefreshOptimized { optimizations.append("Background Refresh") }
        if aggressiveMemoryManagement { optimizations.append("Memory Management") }
        if reduceAnimations { optimizations.append("Reduced Animations") }
        
        return optimizations.isEmpty ? "Basic" : optimizations.joined(separator: ", ")
    }
    
    // MARK: - Preset Configurations
    
    func applyPreset(_ preset: PerformancePreset) {
        switch preset {
        case .balanced:
            applyBalancedSettings()
        case .performanceFirst:
            applyPerformanceFirstSettings()
        case .batteryOptimized:
            applyBatteryOptimizedSettings()
        case .minimal:
            applyMinimalSettings()
        }
    }
    
    private func applyBalancedSettings() {
        isEnabled = true
        aggressiveMemoryManagement = false
        reduceAnimations = false
        limitImageCache = true
        backgroundRefreshOptimized = false
        
        BackgroundRefreshScheduler.shared.setRefreshInterval(3600) // 1 hour
    }
    
    private func applyPerformanceFirstSettings() {
        isEnabled = true
        aggressiveMemoryManagement = true
        reduceAnimations = true
        limitImageCache = true
        backgroundRefreshOptimized = false
        
        BackgroundRefreshScheduler.shared.setRefreshInterval(1800) // 30 minutes
    }
    
    private func applyBatteryOptimizedSettings() {
        isEnabled = true
        aggressiveMemoryManagement = false
        reduceAnimations = true
        limitImageCache = true
        backgroundRefreshOptimized = true
        
        BackgroundRefreshScheduler.shared.setRefreshInterval(14400) // 4 hours
    }
    
    private func applyMinimalSettings() {
        isEnabled = false
        aggressiveMemoryManagement = false
        reduceAnimations = false
        limitImageCache = false
        backgroundRefreshOptimized = false
        
        BackgroundRefreshScheduler.shared.setRefreshInterval(3600) // 1 hour default
    }
}

enum PerformancePreset: String, CaseIterable {
    case balanced = "Balanced"
    case performanceFirst = "Performance First"
    case batteryOptimized = "Battery Optimized"
    case minimal = "Minimal"
    
    var description: String {
        switch self {
        case .balanced:
            return "Good balance of performance and battery life"
        case .performanceFirst:
            return "Maximum performance, may use more battery"
        case .batteryOptimized:
            return "Optimized for battery life"
        case .minimal:
            return "Minimal optimizations, standard behavior"
        }
    }
}
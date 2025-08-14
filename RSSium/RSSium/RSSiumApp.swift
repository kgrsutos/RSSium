import SwiftUI
import BackgroundTasks

@main
struct RSSiumApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var backgroundScheduler = BackgroundRefreshScheduler.shared
    @StateObject private var memoryMonitor = MemoryMonitor.shared
    @StateObject private var performanceOptimizer = PerformanceOptimizer.shared
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Register background tasks
        BackgroundRefreshScheduler.shared.registerBackgroundTasks()
        
        // Apply performance optimizations
        Task { @MainActor in
            PerformanceOptimizer.shared.applyOptimizations()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .background:
                        // Schedule background refresh when app goes to background
                        backgroundScheduler.scheduleBackgroundRefresh()
                        backgroundScheduler.scheduleBackgroundCleanup()
                    case .active:
                        // App became active
                        break
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
        }
    }
}

import Foundation
import BackgroundTasks
import SwiftUI

@MainActor
class BackgroundRefreshScheduler: ObservableObject {
    static let shared = BackgroundRefreshScheduler()
    
    private let refreshTaskIdentifier = "com.rssium.refresh"
    private let cleanupTaskIdentifier = "com.rssium.cleanup"
    
    @AppStorage("backgroundRefreshEnabled") private var isEnabled = true
    @AppStorage("backgroundRefreshInterval") private var refreshInterval: TimeInterval = 3600 // 1 hour default
    @AppStorage("lastBackgroundRefresh") private var lastRefreshTimestamp: TimeInterval = 0
    
    private let refreshService: RefreshService
    private let persistenceService: PersistenceService
    
    private init(
        refreshService: RefreshService = .shared,
        persistenceService: PersistenceService = PersistenceService()
    ) {
        self.refreshService = refreshService
        self.persistenceService = persistenceService
    }
    
    // MARK: - Setup
    
    func registerBackgroundTasks() {
        // Register refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Register cleanup task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: cleanupTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundCleanup(task: task as! BGProcessingTask)
        }
    }
    
    func scheduleBackgroundRefresh() {
        guard isEnabled else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshTaskIdentifier)
            return
        }
        
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: refreshInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled for \(refreshInterval) seconds from now")
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
    }
    
    func scheduleBackgroundCleanup() {
        let request = BGProcessingTaskRequest(identifier: cleanupTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 3600) // Daily cleanup
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background cleanup scheduled")
        } catch {
            print("Failed to schedule background cleanup: \(error)")
        }
    }
    
    // MARK: - Background Task Handlers
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleBackgroundRefresh()
        
        // Create a task to refresh feeds
        let refreshTask = Task {
            do {
                // Perform refresh with timeout
                let refreshTask = Task.detached(priority: .background) {
                    try await self.refreshService.refreshAllFeeds()
                }
                
                // Wait for completion with timeout
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        _ = try await refreshTask.value
                    }
                    
                    group.addTask {
                        try await Task.sleep(nanoseconds: 25_000_000_000) // 25 second timeout
                        throw CancellationError()
                    }
                    
                    try await group.next()
                    group.cancelAll()
                }
                
                lastRefreshTimestamp = Date().timeIntervalSince1970
                task.setTaskCompleted(success: true)
                
            } catch {
                print("Background refresh failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
        
        // Set expiration handler
        task.expirationHandler = {
            refreshTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    private func handleBackgroundCleanup(task: BGProcessingTask) {
        // Schedule next cleanup
        scheduleBackgroundCleanup()
        
        let cleanupTask = Task {
            do {
                // Clean old articles (older than 30 days)
                let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
                
                try await persistenceService.performBackgroundTask { context in
                    let request = Article.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "publishedDate < %@ AND isRead == YES",
                        thirtyDaysAgo as NSDate
                    )
                    
                    let oldArticles = try context.fetch(request)
                    for article in oldArticles {
                        context.delete(article)
                    }
                    
                    if context.hasChanges {
                        try context.save()
                    }
                }
                
                // Clean image cache
                await ImageCacheService.shared.clearCache()
                
                task.setTaskCompleted(success: true)
                
            } catch {
                print("Background cleanup failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
        
        task.expirationHandler = {
            cleanupTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    // MARK: - User Settings
    
    func setRefreshInterval(_ interval: TimeInterval) {
        refreshInterval = interval
        scheduleBackgroundRefresh()
    }
    
    func toggleBackgroundRefresh(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            scheduleBackgroundRefresh()
            scheduleBackgroundCleanup()
        } else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshTaskIdentifier)
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: cleanupTaskIdentifier)
        }
    }
    
    var lastRefreshDate: Date? {
        lastRefreshTimestamp > 0 ? Date(timeIntervalSince1970: lastRefreshTimestamp) : nil
    }
}
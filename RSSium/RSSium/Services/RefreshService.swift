import Foundation
import CoreData
import Combine

enum RefreshError: LocalizedError, Equatable {
    case networkUnavailable
    case noActiveFeeds
    case partialFailure(Int, Int) // (failed count, total count)
    case completeFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection is not available"
        case .noActiveFeeds:
            return "No active feeds to refresh"
        case .partialFailure(let failed, let total):
            return "Failed to refresh \(failed) out of \(total) feeds"
        case .completeFailure(let message):
            return "Refresh failed: \(message)"
        }
    }
}

struct FeedRefreshResult {
    let feed: Feed
    let success: Bool
    let error: Error?
    let newArticlesCount: Int
    
    var isSuccess: Bool { success && error == nil }
}

struct RefreshResult {
    let totalFeeds: Int
    let successfulFeeds: Int
    let failedFeeds: Int
    let feedResults: [FeedRefreshResult]
    let totalNewArticles: Int
    
    var isCompleteSuccess: Bool { failedFeeds == 0 }
    var isPartialSuccess: Bool { successfulFeeds > 0 && failedFeeds > 0 }
    var isCompleteFailure: Bool { successfulFeeds == 0 && failedFeeds > 0 }
}

@MainActor
class RefreshService: ObservableObject {
    static let shared = RefreshService()
    
    @Published var isRefreshing = false
    @Published var refreshProgress: Double = 0.0
    @Published var lastRefreshDate: Date?
    @Published var lastRefreshResult: RefreshResult?
    
    private let persistenceService: PersistenceService
    private let rssService: RSSService
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    private var wasOffline = false
    
    private init(
        persistenceService: PersistenceService = PersistenceService(),
        rssService: RSSService = RSSService.shared
    ) {
        self.persistenceService = persistenceService
        self.rssService = rssService
        self.networkMonitor = NetworkMonitor.shared
        self.wasOffline = !networkMonitor.isConnected
        
        setupAutoSync()
    }
    
    // MARK: - Auto Sync Setup
    
    private func setupAutoSync() {
        networkMonitor.$isConnected
            .dropFirst() // Skip initial value
            .sink { [weak self] isConnected in
                Task { @MainActor [weak self] in
                    await self?.handleNetworkChange(isConnected)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleNetworkChange(_ isConnected: Bool) async {
        if isConnected && wasOffline {
            // Network restored, trigger auto sync
            await performAutoSync()
        }
        wasOffline = !isConnected
    }
    
    private func performAutoSync() async {
        // Only auto-sync if we haven't refreshed recently (within 5 minutes)
        if let lastRefresh = lastRefreshDate,
           Date().timeIntervalSince(lastRefresh) < 300 {
            return
        }
        
        do {
            _ = try await refreshAllFeeds()
            print("Auto-sync completed successfully")
        } catch {
            print("Auto-sync failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods
    
    func refreshAllFeeds() async throws -> RefreshResult {
        guard !isRefreshing else {
            throw RefreshError.completeFailure("Refresh already in progress")
        }
        
        guard networkMonitor.isConnected else {
            throw RefreshError.networkUnavailable
        }
        
        isRefreshing = true
        refreshProgress = 0.0
        
        defer {
            isRefreshing = false
            refreshProgress = 1.0
            lastRefreshDate = Date()
        }
        
        do {
            let activeFeeds = try await getActiveFeeds()
            guard !activeFeeds.isEmpty else {
                throw RefreshError.noActiveFeeds
            }
            
            let result = await refreshFeeds(activeFeeds)
            lastRefreshResult = result
            
            if result.isCompleteFailure {
                throw RefreshError.completeFailure("All feeds failed to refresh")
            } else if result.isPartialSuccess {
                throw RefreshError.partialFailure(result.failedFeeds, result.totalFeeds)
            }
            
            return result
            
        } catch {
            isRefreshing = false
            throw error
        }
    }
    
    func refreshFeed(_ feed: Feed) async -> FeedRefreshResult {
        guard networkMonitor.isConnected else {
            return FeedRefreshResult(
                feed: feed,
                success: false,
                error: RefreshError.networkUnavailable,
                newArticlesCount: 0
            )
        }
        
        guard let feedUrl = feed.url else {
            return FeedRefreshResult(
                feed: feed,
                success: false,
                error: RefreshError.completeFailure("Feed URL is missing"),
                newArticlesCount: 0
            )
        }
        
        do {
            let channel = try await rssService.fetchAndParseFeed(from: feedUrl.absoluteString)
            let newArticlesCount = try await importNewArticles(from: channel, for: feed)
            
            // Update feed's last updated timestamp
            try await updateFeedLastUpdated(feed)
            
            return FeedRefreshResult(
                feed: feed,
                success: true,
                error: nil,
                newArticlesCount: newArticlesCount
            )
            
        } catch {
            return FeedRefreshResult(
                feed: feed,
                success: false,
                error: error,
                newArticlesCount: 0
            )
        }
    }
    
    func canRefresh() -> Bool {
        return networkMonitor.isConnected && !isRefreshing
    }
    
    // MARK: - Private Methods
    
    private func getActiveFeeds() async throws -> [Feed] {
        return try await persistenceService.performBackgroundTask { context in
            let request: NSFetchRequest<Feed> = Feed.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Feed.title, ascending: true)]
            return try context.fetch(request)
        }
    }
    
    private func refreshFeeds(_ feeds: [Feed]) async -> RefreshResult {
        var feedResults: [FeedRefreshResult] = []
        let totalFeeds = feeds.count
        
        for (index, feed) in feeds.enumerated() {
            let result = await refreshFeed(feed)
            feedResults.append(result)
            
            await MainActor.run {
                refreshProgress = Double(index + 1) / Double(totalFeeds)
            }
        }
        
        let successfulFeeds = feedResults.filter { $0.isSuccess }.count
        let failedFeeds = feedResults.filter { !$0.isSuccess }.count
        let totalNewArticles = feedResults.reduce(0) { $0 + $1.newArticlesCount }
        
        return RefreshResult(
            totalFeeds: totalFeeds,
            successfulFeeds: successfulFeeds,
            failedFeeds: failedFeeds,
            feedResults: feedResults,
            totalNewArticles: totalNewArticles
        )
    }
    
    private func importNewArticles(from channel: RSSChannel, for feed: Feed) async throws -> Int {
        let rssItems = channel.items
        guard !rssItems.isEmpty else { return 0 }
        
        return try await persistenceService.performBackgroundTask { context in
            guard let feedId = feed.id else { return 0 }
            
            // Fetch the feed in this context
            let feedRequest: NSFetchRequest<Feed> = Feed.fetchRequest()
            feedRequest.predicate = NSPredicate(format: "id == %@", feedId as CVarArg)
            guard let contextFeed = try context.fetch(feedRequest).first else { return 0 }
            
            var newArticlesCount = 0
            
            for rssItem in rssItems {
                // Check if article already exists
                let articleRequest: NSFetchRequest<Article> = Article.fetchRequest()
                articleRequest.predicate = NSPredicate(format: "url == %@ AND feed == %@", 
                                                     rssItem.link ?? "", contextFeed)
                articleRequest.fetchLimit = 1
                
                let existingArticles = try context.fetch(articleRequest)
                
                if existingArticles.isEmpty {
                    // Create new article
                    let article = Article(context: context)
                    article.id = UUID()
                    article.title = rssItem.title
                    article.content = rssItem.description
                    article.summary = rssItem.description?.prefix(200).description
                    article.author = rssItem.author
                    article.publishedDate = rssItem.pubDate ?? Date()
                    article.url = rssItem.link.flatMap { URL(string: $0) }
                    article.isRead = false
                    article.feed = contextFeed
                    
                    newArticlesCount += 1
                }
            }
            
            if newArticlesCount > 0 {
                try context.save()
            }
            
            return newArticlesCount
        }
    }
    
    private func updateFeedLastUpdated(_ feed: Feed) async throws {
        try await persistenceService.performBackgroundTask { context in
            guard let feedId = feed.id else { return }
            
            let feedRequest: NSFetchRequest<Feed> = Feed.fetchRequest()
            feedRequest.predicate = NSPredicate(format: "id == %@", feedId as CVarArg)
            
            if let contextFeed = try context.fetch(feedRequest).first {
                contextFeed.lastUpdated = Date()
                try context.save()
            }
        }
    }
}
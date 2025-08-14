import Foundation
import SwiftUI
import Combine

@MainActor
class FeedListViewModel: ObservableObject {
    @Published var feeds: [Feed] = []
    @Published var unreadCounts: [UUID: Int] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var errorRecoverySuggestion: String?
    @Published var shouldShowRetryOption = false
    @Published var showingAddFeed = false
    @Published var refreshProgress: Double = 0.0
    @Published var lastRefreshDate: Date?
    @Published var feedRefreshErrors: [UUID: String] = [:]
    
    private let persistenceService: PersistenceService
    private let rssService: RSSService
    private let refreshService: RefreshService
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    
    // Retry state
    private var lastFailedAction: (() async -> Void)?
    private var lastFailedFeedURL: String?
    
    init(
        persistenceService: PersistenceService = PersistenceService(),
        rssService: RSSService = .shared,
        refreshService: RefreshService = .shared,
        networkMonitor: NetworkMonitor = .shared,
        autoLoadFeeds: Bool = true
    ) {
        self.persistenceService = persistenceService
        self.rssService = rssService
        self.refreshService = refreshService
        self.networkMonitor = networkMonitor
        
        // Load feeds asynchronously to improve launch time
        if autoLoadFeeds {
            Task { @MainActor in
                await loadFeedsAsync()
            }
        }
        setupRefreshServiceBinding()
    }
    
    func loadFeeds() {
        do {
            feeds = try persistenceService.fetchActiveFeeds()
            updateUnreadCounts()
        } catch {
            errorMessage = "Failed to load feeds: \(error.localizedDescription)"
        }
    }
    
    func loadFeedsAsync() async {
        isLoading = true
        do {
            // Load feeds in background to avoid blocking UI
            let loadedFeeds = try await Task.detached(priority: .userInitiated) {
                try self.persistenceService.fetchActiveFeeds()
            }.value
            
            await MainActor.run {
                self.feeds = loadedFeeds
                self.updateUnreadCounts()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load feeds: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func addFeed(url: String, title: String? = nil) async {
        guard !url.isEmpty else {
            errorMessage = "URL cannot be empty"
            return
        }
        
        guard rssService.validateFeedURL(url) else {
            errorMessage = "Invalid URL format"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let channel = try await rssService.fetchAndParseFeed(from: url)
            let feedTitle = title?.isEmpty == false ? title! : channel.title
            
            guard let feedURL = URL(string: url) else {
                throw RSSError.invalidURL
            }
            
            let feed = try persistenceService.createFeed(title: feedTitle, url: feedURL)
            
            let parsedArticles = channel.items.map { item in
                (
                    title: item.title,
                    content: item.description,
                    summary: item.description,
                    author: item.author,
                    publishedDate: item.pubDate ?? Date(),
                    url: item.link.flatMap { URL(string: $0) }
                )
            }
            
            try await persistenceService.importArticles(from: parsedArticles, for: feed)
            
            loadFeeds()
            showingAddFeed = false
            
        } catch let error as RSSError {
            handleError(error)
            lastFailedAction = { [weak self] in
                await self?.addFeed(url: url, title: title)
            }
            lastFailedFeedURL = url
        } catch {
            handleGenericError(error, context: "adding feed")
            lastFailedAction = { [weak self] in
                await self?.addFeed(url: url, title: title)
            }
            lastFailedFeedURL = url
        }
        
        isLoading = false
    }
    
    func deleteFeed(_ feed: Feed) {
        do {
            try persistenceService.deleteFeed(feed)
            loadFeeds()
        } catch {
            errorMessage = "Failed to delete feed: \(error.localizedDescription)"
        }
    }
    
    func deleteFeeds(at offsets: IndexSet) {
        let feedsToDelete = offsets.map { feeds[$0] }
        do {
            try persistenceService.deleteFeeds(feedsToDelete)
            loadFeeds()
        } catch {
            errorMessage = "Failed to delete feeds: \(error.localizedDescription)"
        }
    }
    
    func refreshFeed(_ feed: Feed) async {
        guard networkMonitor.isConnected else {
            if let feedId = feed.id {
                feedRefreshErrors[feedId] = "No network connection"
            }
            return
        }
        
        let result = await refreshService.refreshFeed(feed)
        
        if let feedId = feed.id {
            if result.isSuccess {
                feedRefreshErrors.removeValue(forKey: feedId)
            } else if let error = result.error {
                feedRefreshErrors[feedId] = error.localizedDescription
            }
        }
        
        loadFeeds()
    }
    
    func refreshAllFeeds() async {
        guard networkMonitor.isConnected else {
            errorMessage = "No network connection available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        feedRefreshErrors.removeAll()
        
        do {
            let result = try await refreshService.refreshAllFeeds()
            
            // Update individual feed errors
            for feedResult in result.feedResults {
                if let feedId = feedResult.feed.id {
                    if !feedResult.isSuccess, let error = feedResult.error {
                        feedRefreshErrors[feedId] = error.localizedDescription
                    }
                }
            }
            
            // Set appropriate success/error message
            if result.isCompleteSuccess {
                errorMessage = nil
            } else if result.isPartialSuccess {
                errorMessage = "Some feeds failed to refresh (\(result.failedFeeds)/\(result.totalFeeds))"
            }
            
            loadFeeds()
            lastRefreshDate = Date()
            
        } catch {
            handleGenericError(error, context: "refreshing all feeds")
            lastFailedAction = { [weak self] in
                await self?.refreshAllFeeds()
            }
        }
        
        isLoading = false
    }
    
    func markAllAsRead(for feed: Feed? = nil) {
        do {
            try persistenceService.markAllArticlesAsRead(for: feed)
            updateUnreadCounts()
        } catch {
            errorMessage = "Failed to mark articles as read: \(error.localizedDescription)"
        }
    }
    
    func getUnreadCount(for feed: Feed) -> Int {
        guard let feedId = feed.id else { return 0 }
        return unreadCounts[feedId] ?? 0
    }
    
    func getTotalUnreadCount() -> Int {
        return unreadCounts.values.reduce(0, +)
    }
    
    private func updateUnreadCounts() {
        do {
            // Use batch query to get all unread counts in a single database operation
            unreadCounts = try persistenceService.getUnreadCountsForAllFeeds()
        } catch {
            print("Error getting batch unread counts: \(error)")
            // Fallback to individual queries if batch operation fails
            var newUnreadCounts: [UUID: Int] = [:]
            
            for feed in feeds {
                guard let feedId = feed.id else { continue }
                do {
                    let count = try persistenceService.getUnreadCount(for: feed)
                    newUnreadCounts[feedId] = count
                } catch {
                    print("Error getting unread count for feed \(feed.title ?? "Unknown"): \(error)")
                    newUnreadCounts[feedId] = 0
                }
            }
            
            unreadCounts = newUnreadCounts
        }
    }
    
    func clearError() {
        errorMessage = nil
        errorRecoverySuggestion = nil
        shouldShowRetryOption = false
        lastFailedAction = nil
        lastFailedFeedURL = nil
    }
    
    func retryLastAction() async {
        guard let action = lastFailedAction else { return }
        clearError()
        await action()
    }
    
    private func handleError(_ error: RSSError) {
        errorMessage = error.localizedDescription
        errorRecoverySuggestion = error.recoverySuggestion
        shouldShowRetryOption = canRetryError(error)
    }
    
    private func handleGenericError(_ error: Error, context: String) {
        errorMessage = "Failed to \(context): \(error.localizedDescription)"
        errorRecoverySuggestion = "Check your internet connection and try again"
        shouldShowRetryOption = true
    }
    
    private func canRetryError(_ error: RSSError) -> Bool {
        switch error {
        case .networkError, .connectionTimeout, .serverError:
            return true
        case .invalidURL, .invalidFeedFormat, .emptyResponse, .unsupportedEncoding:
            return false
        case .parsingError:
            return false
        }
    }
    
    func hasRefreshError(for feed: Feed) -> Bool {
        guard let feedId = feed.id else { return false }
        return feedRefreshErrors[feedId] != nil
    }
    
    func getRefreshError(for feed: Feed) -> String? {
        guard let feedId = feed.id else { return nil }
        return feedRefreshErrors[feedId]
    }
    
    func canRefresh() -> Bool {
        return refreshService.canRefresh()
    }
    
    private func setupRefreshServiceBinding() {
        refreshService.$refreshProgress
            .receive(on: DispatchQueue.main)
            .assign(to: \.refreshProgress, on: self)
            .store(in: &cancellables)
        
        refreshService.$lastRefreshDate
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastRefreshDate, on: self)
            .store(in: &cancellables)
    }
}
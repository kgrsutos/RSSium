import Foundation
import SwiftUI
import Combine

@MainActor
class FeedListViewModel: ObservableObject {
    @Published var feeds: [Feed] = []
    @Published var unreadCounts: [UUID: Int] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddFeed = false
    
    private let persistenceService: PersistenceService
    private let rssService: RSSService
    private var cancellables = Set<AnyCancellable>()
    
    init(persistenceService: PersistenceService = PersistenceService(), rssService: RSSService = .shared) {
        self.persistenceService = persistenceService
        self.rssService = rssService
        loadFeeds()
    }
    
    func loadFeeds() {
        do {
            feeds = try persistenceService.fetchActiveFeeds()
            updateUnreadCounts()
        } catch {
            errorMessage = "Failed to load feeds: \(error.localizedDescription)"
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
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to add feed: \(error.localizedDescription)"
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
        guard let urlString = feed.url?.absoluteString else {
            errorMessage = "Invalid feed URL"
            return
        }
        
        do {
            let channel = try await rssService.fetchAndParseFeed(from: urlString)
            
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
            
        } catch let error as RSSError {
            errorMessage = "Failed to refresh feed: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to refresh feed: \(error.localizedDescription)"
        }
    }
    
    func refreshAllFeeds() async {
        isLoading = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            for feed in feeds {
                group.addTask {
                    await self.refreshFeed(feed)
                }
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
    
    func clearError() {
        errorMessage = nil
    }
}
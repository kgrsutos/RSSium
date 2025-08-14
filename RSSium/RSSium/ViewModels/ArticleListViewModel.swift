import Foundation
import SwiftUI
import Combine

@MainActor
class ArticleListViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var selectedFilter: ArticleFilter = .all
    @Published var hasMoreArticles = false
    @Published var isLoadingMore = false
    
    let feed: Feed
    private let persistenceService: PersistenceService
    private let rssService: RSSService
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    
    // Pagination support for large feeds
    private let pageSize = 25
    private var currentPage = 0
    private var allArticles: [Article] = []
    
    enum ArticleFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        
        var systemImage: String {
            switch self {
            case .all: return "tray.full"
            case .unread: return "circle.fill"
            }
        }
    }
    
    init(feed: Feed, persistenceService: PersistenceService = PersistenceService(), rssService: RSSService = .shared, networkMonitor: NetworkMonitor = .shared) {
        self.feed = feed
        self.persistenceService = persistenceService
        self.rssService = rssService
        self.networkMonitor = networkMonitor
        loadArticles()
    }
    
    func loadArticles() {
        isLoading = true
        currentPage = 0
        
        do {
            switch selectedFilter {
            case .all:
                allArticles = try persistenceService.fetchArticles(for: feed)
            case .unread:
                allArticles = try persistenceService.fetchUnreadArticles(for: feed)
            }
            
            // Load first page
            loadPage()
            isLoading = false
        } catch {
            errorMessage = "Failed to load articles: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func loadPage() {
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, allArticles.count)
        
        if startIndex < allArticles.count {
            let newArticles = Array(allArticles[startIndex..<endIndex])
            
            if currentPage == 0 {
                articles = newArticles
            } else {
                articles.append(contentsOf: newArticles)
            }
            
            hasMoreArticles = endIndex < allArticles.count
        } else {
            hasMoreArticles = false
        }
    }
    
    func loadMoreArticles() {
        guard hasMoreArticles && !isLoadingMore else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        // Simulate small delay for smooth scrolling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.loadPage()
            self?.isLoadingMore = false
        }
    }
    
    func refreshFeed() async {
        guard !isRefreshing else { return }
        guard let urlString = feed.url?.absoluteString else {
            errorMessage = "Invalid feed URL"
            return
        }
        
        guard networkMonitor.isConnected else {
            errorMessage = "Network connection is required to refresh feeds"
            return
        }
        
        isRefreshing = true
        errorMessage = nil
        
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
            
            await MainActor.run {
                self.loadArticles()
            }
            
        } catch let error as RSSError {
            await MainActor.run {
                self.errorMessage = "Failed to refresh feed: \(error.localizedDescription)"
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to refresh feed: \(error.localizedDescription)"
            }
        }
        
        isRefreshing = false
    }
    
    func markArticleAsRead(_ article: Article) {
        do {
            try persistenceService.markArticleAsRead(article)
            if selectedFilter == .unread {
                articles.removeAll { $0.id == article.id }
            }
        } catch {
            errorMessage = "Failed to mark article as read: \(error.localizedDescription)"
        }
    }
    
    func markArticleAsUnread(_ article: Article) {
        do {
            // Since PersistenceService doesn't have a method for marking as unread,
            // we'll update the article and use the updateFeed method to save changes
            article.markAsUnread()
            if let feed = article.feed {
                try persistenceService.updateFeed(feed)
            }
            if selectedFilter == .unread {
                loadArticles()
            }
        } catch {
            errorMessage = "Failed to mark article as unread: \(error.localizedDescription)"
        }
    }
    
    func toggleReadState(for article: Article) {
        if article.isRead {
            markArticleAsUnread(article)
        } else {
            markArticleAsRead(article)
        }
    }
    
    func markAllAsRead() {
        do {
            try persistenceService.markAllArticlesAsRead(for: feed)
            // Update local state immediately for better UX
            allArticles.forEach { $0.isRead = true }
            articles.forEach { $0.isRead = true }
            
            if selectedFilter == .unread {
                articles.removeAll()
                allArticles.removeAll()
                hasMoreArticles = false
            }
        } catch {
            errorMessage = "Failed to mark all as read: \(error.localizedDescription)"
        }
    }
    
    func deleteArticle(_ article: Article) {
        do {
            try persistenceService.deleteArticle(article)
            articles.removeAll { $0.id == article.id }
        } catch {
            errorMessage = "Failed to delete article: \(error.localizedDescription)"
        }
    }
    
    func deleteArticles(at offsets: IndexSet) {
        let articlesToDelete = offsets.map { articles[$0] }
        do {
            try persistenceService.deleteArticles(articlesToDelete)
            articles.remove(atOffsets: offsets)
        } catch {
            errorMessage = "Failed to delete articles: \(error.localizedDescription)"
        }
    }
    
    func changeFilter(to filter: ArticleFilter) {
        selectedFilter = filter
        loadArticles()
    }
    
    var feedTitle: String {
        feed.title ?? "Unknown Feed"
    }
    
    var articleCount: Int {
        articles.count
    }
    
    var unreadCount: Int {
        articles.filter { !$0.isRead }.count
    }
    
    func clearError() {
        errorMessage = nil
    }
}
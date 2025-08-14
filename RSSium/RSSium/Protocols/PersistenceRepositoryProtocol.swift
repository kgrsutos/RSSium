import Foundation
import CoreData

/// Persistence層の抽象化プロトコル
/// テスト時はこのプロトコルに準拠したモック実装を使用
protocol PersistenceRepositoryProtocol {
    // MARK: - Feed Operations
    func fetchAllFeeds() async throws -> [Feed]
    func fetchActiveFeeds() async throws -> [Feed]
    func fetchFeed(by id: UUID) async throws -> Feed?
    func createFeed(title: String, url: URL, iconURL: URL?) async throws -> Feed
    func updateFeed(_ feed: Feed) async throws
    func deleteFeed(_ feed: Feed) async throws
    func deleteFeeds(_ feeds: [Feed]) async throws
    
    // MARK: - Article Operations
    func fetchArticles(for feed: Feed) async throws -> [Article]
    func fetchUnreadArticles(for feed: Feed?) async throws -> [Article]
    func fetchArticle(by id: UUID) async throws -> Article?
    func createArticle(title: String, content: String?, summary: String?, author: String?, publishedDate: Date, url: URL?, feed: Feed) async throws -> Article
    func markArticleAsRead(_ article: Article) async throws
    func markArticlesAsRead(_ articles: [Article]) async throws
    func deleteArticle(_ article: Article) async throws
    func deleteAllArticles(for feed: Feed) async throws
    func markAllArticlesAsRead(for feed: Feed?) async throws
    
    // MARK: - Statistics
    func getUnreadCount(for feed: Feed?) async throws -> Int
    func getTotalArticleCount(for feed: Feed?) async throws -> Int
}

/// Core Data実装
class CoreDataPersistenceRepository: PersistenceRepositoryProtocol {
    private let persistenceService: PersistenceService
    
    init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
    }
    
    func fetchAllFeeds() async throws -> [Feed] {
        try persistenceService.fetchAllFeeds()
    }
    
    func fetchActiveFeeds() async throws -> [Feed] {
        try persistenceService.fetchActiveFeeds()
    }
    
    func fetchFeed(by id: UUID) async throws -> Feed? {
        try persistenceService.fetchFeed(by: id)
    }
    
    func createFeed(title: String, url: URL, iconURL: URL?) async throws -> Feed {
        try persistenceService.createFeed(title: title, url: url, iconURL: iconURL)
    }
    
    func updateFeed(_ feed: Feed) async throws {
        try persistenceService.updateFeed(feed)
    }
    
    func deleteFeed(_ feed: Feed) async throws {
        try persistenceService.deleteFeed(feed)
    }
    
    func deleteFeeds(_ feeds: [Feed]) async throws {
        try persistenceService.deleteFeeds(feeds)
    }
    
    func fetchArticles(for feed: Feed) async throws -> [Article] {
        try persistenceService.fetchArticles(for: feed)
    }
    
    func fetchUnreadArticles(for feed: Feed?) async throws -> [Article] {
        if let feed = feed {
            return try persistenceService.fetchUnreadArticles(for: feed)
        } else {
            return try persistenceService.fetchUnreadArticles()
        }
    }
    
    func fetchArticle(by id: UUID) async throws -> Article? {
        try persistenceService.fetchArticle(by: id)
    }
    
    func createArticle(title: String, content: String?, summary: String?, author: String?, publishedDate: Date, url: URL?, feed: Feed) async throws -> Article {
        try persistenceService.createArticle(
            title: title,
            content: content,
            summary: summary,
            author: author,
            publishedDate: publishedDate,
            url: url,
            feed: feed
        )
    }
    
    func markArticleAsRead(_ article: Article) async throws {
        try persistenceService.markArticleAsRead(article)
    }
    
    func markArticlesAsRead(_ articles: [Article]) async throws {
        try persistenceService.markArticlesAsRead(articles)
    }
    
    func deleteArticle(_ article: Article) async throws {
        try persistenceService.deleteArticle(article)
    }
    
    func deleteAllArticles(for feed: Feed) async throws {
        try persistenceService.deleteAllArticles(for: feed)
    }
    
    func markAllArticlesAsRead(for feed: Feed?) async throws {
        try persistenceService.markAllArticlesAsRead(for: feed)
    }
    
    func getUnreadCount(for feed: Feed?) async throws -> Int {
        try persistenceService.getUnreadCount(for: feed)
    }
    
    func getTotalArticleCount(for feed: Feed?) async throws -> Int {
        try persistenceService.getTotalArticleCount(for: feed)
    }
}
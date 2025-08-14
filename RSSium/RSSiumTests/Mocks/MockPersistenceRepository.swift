import Foundation
import CoreData
@testable import RSSium

/// テスト用のインメモリモック実装
/// Core Dataを使用せず、完全に予測可能な動作を保証
class MockPersistenceRepository: PersistenceRepositoryProtocol {
    
    // In-memory storage
    private var feeds: [MockFeed] = []
    private var articles: [MockArticle] = []
    
    // MARK: - Mock Data Models
    
    class MockFeed {
        let id: UUID
        var title: String
        var url: URL
        var iconURL: URL?
        var lastUpdated: Date
        var isActive: Bool
        
        init(id: UUID = UUID(), title: String, url: URL, iconURL: URL? = nil, isActive: Bool = true) {
            self.id = id
            self.title = title
            self.url = url
            self.iconURL = iconURL
            self.lastUpdated = Date()
            self.isActive = isActive
        }
        
        func toFeed(context: NSManagedObjectContext) -> Feed {
            let feed = Feed(context: context)
            feed.id = self.id
            feed.title = self.title
            feed.url = self.url
            feed.iconURL = self.iconURL
            feed.lastUpdated = self.lastUpdated
            feed.isActive = self.isActive
            return feed
        }
    }
    
    class MockArticle {
        let id: UUID
        var title: String
        var content: String?
        var summary: String?
        var author: String?
        var publishedDate: Date
        var url: URL?
        var isRead: Bool
        var feedId: UUID
        
        init(id: UUID = UUID(), title: String, content: String? = nil, summary: String? = nil,
             author: String? = nil, publishedDate: Date = Date(), url: URL? = nil,
             isRead: Bool = false, feedId: UUID) {
            self.id = id
            self.title = title
            self.content = content
            self.summary = summary
            self.author = author
            self.publishedDate = publishedDate
            self.url = url
            self.isRead = isRead
            self.feedId = feedId
        }
        
        func toArticle(context: NSManagedObjectContext, feed: Feed) -> Article {
            let article = Article(context: context)
            article.id = self.id
            article.title = self.title
            article.content = self.content
            article.summary = self.summary
            article.author = self.author
            article.publishedDate = self.publishedDate
            article.url = self.url
            article.isRead = self.isRead
            article.feed = feed
            return article
        }
    }
    
    // Helper to create Core Data objects for return values
    private lazy var mockContext: NSManagedObjectContext = {
        let container = NSPersistentContainer(name: "RSSiumModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, _ in }
        return container.viewContext
    }()
    
    // MARK: - Feed Operations
    
    func fetchAllFeeds() async throws -> [Feed] {
        return feeds.map { $0.toFeed(context: mockContext) }
    }
    
    func fetchActiveFeeds() async throws -> [Feed] {
        return feeds.filter { $0.isActive }.map { $0.toFeed(context: mockContext) }
    }
    
    func fetchFeed(by id: UUID) async throws -> Feed? {
        return feeds.first { $0.id == id }?.toFeed(context: mockContext)
    }
    
    func createFeed(title: String, url: URL, iconURL: URL?) async throws -> Feed {
        let mockFeed = MockFeed(title: title, url: url, iconURL: iconURL)
        feeds.append(mockFeed)
        return mockFeed.toFeed(context: mockContext)
    }
    
    func updateFeed(_ feed: Feed) async throws {
        guard let index = feeds.firstIndex(where: { $0.id == feed.id }) else { return }
        feeds[index].title = feed.title ?? ""
        feeds[index].url = feed.url ?? URL(string: "https://example.com")!
        feeds[index].iconURL = feed.iconURL
        feeds[index].isActive = feed.isActive
    }
    
    func deleteFeed(_ feed: Feed) async throws {
        feeds.removeAll { $0.id == feed.id }
        articles.removeAll { $0.feedId == feed.id }
    }
    
    func deleteFeeds(_ feedsToDelete: [Feed]) async throws {
        let idsToDelete = feedsToDelete.compactMap { $0.id }
        feeds.removeAll { feed in idsToDelete.contains(feed.id) }
        articles.removeAll { article in idsToDelete.contains(article.feedId) }
    }
    
    // MARK: - Article Operations
    
    func fetchArticles(for feed: Feed) async throws -> [Article] {
        guard let feedId = feed.id else { return [] }
        return articles
            .filter { $0.feedId == feedId }
            .compactMap { mockArticle in
                guard let mockFeed = feeds.first(where: { $0.id == feedId }) else { return nil }
                let feed = mockFeed.toFeed(context: mockContext)
                return mockArticle.toArticle(context: mockContext, feed: feed)
            }
    }
    
    func fetchUnreadArticles(for feed: Feed?) async throws -> [Article] {
        let filteredArticles: [MockArticle]
        if let feed = feed, let feedId = feed.id {
            filteredArticles = articles.filter { $0.feedId == feedId && !$0.isRead }
        } else {
            filteredArticles = articles.filter { !$0.isRead }
        }
        
        return filteredArticles.compactMap { mockArticle in
            guard let mockFeed = feeds.first(where: { $0.id == mockArticle.feedId }) else { return nil }
            let feed = mockFeed.toFeed(context: mockContext)
            return mockArticle.toArticle(context: mockContext, feed: feed)
        }
    }
    
    func fetchArticle(by id: UUID) async throws -> Article? {
        guard let mockArticle = articles.first(where: { $0.id == id }),
              let mockFeed = feeds.first(where: { $0.id == mockArticle.feedId }) else {
            return nil
        }
        let feed = mockFeed.toFeed(context: mockContext)
        return mockArticle.toArticle(context: mockContext, feed: feed)
    }
    
    func createArticle(title: String, content: String?, summary: String?, author: String?,
                      publishedDate: Date, url: URL?, feed: Feed) async throws -> Article {
        guard let feedId = feed.id else {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Feed ID is nil"])
        }
        
        let mockArticle = MockArticle(
            title: title,
            content: content,
            summary: summary,
            author: author,
            publishedDate: publishedDate,
            url: url,
            feedId: feedId
        )
        articles.append(mockArticle)
        return mockArticle.toArticle(context: mockContext, feed: feed)
    }
    
    func markArticleAsRead(_ article: Article) async throws {
        guard let id = article.id,
              let index = articles.firstIndex(where: { $0.id == id }) else { return }
        articles[index].isRead = true
    }
    
    func markArticlesAsRead(_ articlesToMark: [Article]) async throws {
        let idsToMark = articlesToMark.compactMap { $0.id }
        for id in idsToMark {
            if let index = articles.firstIndex(where: { $0.id == id }) {
                articles[index].isRead = true
            }
        }
    }
    
    func deleteArticle(_ article: Article) async throws {
        guard let id = article.id else { return }
        articles.removeAll { $0.id == id }
    }
    
    func deleteAllArticles(for feed: Feed) async throws {
        guard let feedId = feed.id else { return }
        articles.removeAll { $0.feedId == feedId }
    }
    
    func markAllArticlesAsRead(for feed: Feed?) async throws {
        if let feed = feed, let feedId = feed.id {
            for index in articles.indices where articles[index].feedId == feedId {
                articles[index].isRead = true
            }
        } else {
            for index in articles.indices {
                articles[index].isRead = true
            }
        }
    }
    
    // MARK: - Statistics
    
    func getUnreadCount(for feed: Feed?) async throws -> Int {
        if let feed = feed, let feedId = feed.id {
            return articles.filter { $0.feedId == feedId && !$0.isRead }.count
        } else {
            return articles.filter { !$0.isRead }.count
        }
    }
    
    func getTotalArticleCount(for feed: Feed?) async throws -> Int {
        if let feed = feed, let feedId = feed.id {
            return articles.filter { $0.feedId == feedId }.count
        } else {
            return articles.count
        }
    }
    
    // MARK: - Test Helpers
    
    /// テスト用：全データをクリア
    func reset() {
        feeds.removeAll()
        articles.removeAll()
    }
    
    /// テスト用：現在のデータ状態を取得
    func getCurrentState() -> (feeds: Int, articles: Int, unreadArticles: Int) {
        return (
            feeds: feeds.count,
            articles: articles.count,
            unreadArticles: articles.filter { !$0.isRead }.count
        )
    }
}
import Testing
import CoreData
@testable import RSSium

struct PersistenceServiceTests {
    
    private func createTestStack() -> (PersistenceController, PersistenceService) {
        // Use in-memory instance to avoid Core Data conflicts
        let controller = PersistenceController(inMemory: true)
        let service = PersistenceService(persistenceController: controller)
        
        // Clear any existing data
        let context = controller.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Feed.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        _ = try? context.execute(deleteRequest)
        
        let articleFetchRequest: NSFetchRequest<NSFetchRequestResult> = Article.fetchRequest()
        let articleDeleteRequest = NSBatchDeleteRequest(fetchRequest: articleFetchRequest)
        _ = try? context.execute(articleDeleteRequest)
        
        try? context.save()
        
        return (controller, service)
    }
    
    // MARK: - Feed Tests
    
    @Test func createAndFetchFeed() async throws {
        let (_, service) = createTestStack()
        
        let title = "Test Feed"
        let url = URL(string: "https://example.com/feed.xml")!
        
        let feed = try service.createFeed(title: title, url: url)
        
        #expect(feed.title == title)
        #expect(feed.url == url)
        #expect(feed.isActive == true)
        #expect(feed.lastUpdated != nil)
        
        let fetchedFeeds = try service.fetchAllFeeds()
        #expect(fetchedFeeds.count == 1)
        #expect(fetchedFeeds.first?.id == feed.id)
    }
    
    @Test func fetchActiveFeedsOnly() async throws {
        let (_, service) = createTestStack()
        
        let activeFeed = try service.createFeed(
            title: "Active Feed",
            url: URL(string: "https://active.com/feed.xml")!
        )
        
        let inactiveFeed = try service.createFeed(
            title: "Inactive Feed",
            url: URL(string: "https://inactive.com/feed.xml")!
        )
        inactiveFeed.isActive = false
        try service.updateFeed(inactiveFeed)
        
        let activeFeeds = try service.fetchActiveFeeds()
        #expect(activeFeeds.count == 1)
        #expect(activeFeeds.first?.id == activeFeed.id)
    }
    
    @Test func fetchFeedById() async throws {
        let (_, service) = createTestStack()
        
        let feed = try service.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        let fetchedFeed = try service.fetchFeed(by: feed.id!)
        #expect(fetchedFeed?.id == feed.id)
        #expect(fetchedFeed?.title == feed.title)
        
        let nonExistentFeed = try service.fetchFeed(by: UUID())
        #expect(nonExistentFeed == nil)
    }
    
    @Test func updateFeed() async throws {
        let (_, service) = createTestStack()
        
        let feed = try service.createFeed(
            title: "Original Title",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        feed.title = "Updated Title"
        feed.iconURL = URL(string: "https://example.com/icon.png")
        try service.updateFeed(feed)
        
        let fetchedFeed = try service.fetchFeed(by: feed.id!)
        #expect(fetchedFeed?.title == "Updated Title")
        #expect(fetchedFeed?.iconURL?.absoluteString == "https://example.com/icon.png")
    }
    
    @Test func deleteFeed() async throws {
        let (_, service) = createTestStack()
        
        let feed = try service.createFeed(
            title: "Feed to Delete",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        try service.deleteFeed(feed)
        
        let feeds = try service.fetchAllFeeds()
        #expect(feeds.isEmpty)
    }
    
    @Test func deleteMultipleFeeds() async throws {
        let (_, service) = createTestStack()
        
        let feed1 = try service.createFeed(
            title: "Feed 1",
            url: URL(string: "https://example1.com/feed.xml")!
        )
        let feed2 = try service.createFeed(
            title: "Feed 2",
            url: URL(string: "https://example2.com/feed.xml")!
        )
        let feed3 = try service.createFeed(
            title: "Feed 3",
            url: URL(string: "https://example3.com/feed.xml")!
        )
        
        try service.deleteFeeds([feed1, feed2])
        
        let remainingFeeds = try service.fetchAllFeeds()
        #expect(remainingFeeds.count == 1)
        #expect(remainingFeeds.first?.id == feed3.id)
    }
    
    // MARK: - Article Tests
    
    @Test func createAndFetchArticle() async throws {
        let (_, service) = createTestStack()
        
        let feed = try service.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        let article = try service.createArticle(
            title: "Test Article",
            content: "Article content",
            summary: "Article summary",
            author: "Test Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/article"),
            feed: feed
        )
        
        #expect(article.title == "Test Article")
        #expect(article.isRead == false)
        #expect(article.feed?.id == feed.id)
        
        let fetchedArticles = try service.fetchArticles(for: feed)
        #expect(fetchedArticles.count == 1)
        #expect(fetchedArticles.first?.id == article.id)
    }
    
    @Test func fetchUnreadArticles() async throws {
        let (_, service) = createTestStack()
        
        let feed = try service.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        let unreadArticle = try service.createArticle(
            title: "Unread Article",
            content: nil,
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: nil,
            feed: feed
        )
        
        let readArticle = try service.createArticle(
            title: "Read Article",
            content: nil,
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: nil,
            feed: feed
        )
        try service.markArticleAsRead(readArticle)
        
        let unreadArticles = try service.fetchUnreadArticles(for: feed)
        #expect(unreadArticles.count == 1)
        #expect(unreadArticles.first?.id == unreadArticle.id)
        
        let allUnreadArticles = try service.fetchUnreadArticles()
        #expect(allUnreadArticles.count == 1)
    }
    
    @Test func markArticleAsRead() async throws {
        let (_, service) = createTestStack()
        
        let feed = try service.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        let article = try service.createArticle(
            title: "Test Article",
            content: nil,
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: nil,
            feed: feed
        )
        
        #expect(article.isRead == false)
        
        try service.markArticleAsRead(article)
        
        let fetchedArticle = try service.fetchArticle(by: article.id!)
        #expect(fetchedArticle?.isRead == true)
    }
    
    @Test func markMultipleArticlesAsRead() async throws {
        let (_, service) = createTestStack()
        
        let feed = try service.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        let articles = try (1...3).map { index in
            try service.createArticle(
                title: "Article \(index)",
                content: nil,
                summary: nil,
                author: nil,
                publishedDate: Date(),
                url: nil,
                feed: feed
            )
        }
        
        try service.markArticlesAsRead(Array(articles.prefix(2)))
        
        let unreadArticles = try service.fetchUnreadArticles(for: feed)
        #expect(unreadArticles.count == 1)
        #expect(unreadArticles.first?.id == articles[2].id)
    }
    
    @Test func deleteArticle() async throws {
        let (_, service) = createTestStack()
        
        let feed = try service.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        let article = try service.createArticle(
            title: "Article to Delete",
            content: nil,
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: nil,
            feed: feed
        )
        
        try service.deleteArticle(article)
        
        let articles = try service.fetchArticles(for: feed)
        #expect(articles.isEmpty)
    }
    
    // MARK: - Batch Operations Tests
    
    @Test func deleteAllArticlesForFeed() async throws {
        let (_, service) = createTestStack()
        
        let feed1 = try service.createFeed(
            title: "Feed 1",
            url: URL(string: "https://example1.com/feed.xml")!
        )
        let feed2 = try service.createFeed(
            title: "Feed 2",
            url: URL(string: "https://example2.com/feed.xml")!
        )
        
        for i in 1...3 {
            _ = try service.createArticle(
                title: "Feed 1 Article \(i)",
                content: nil,
                summary: nil,
                author: nil,
                publishedDate: Date(),
                url: nil,
                feed: feed1
            )
            _ = try service.createArticle(
                title: "Feed 2 Article \(i)",
                content: nil,
                summary: nil,
                author: nil,
                publishedDate: Date(),
                url: nil,
                feed: feed2
            )
        }
        
        try service.deleteAllArticles(for: feed1)
        
        let feed1Articles = try service.fetchArticles(for: feed1)
        let feed2Articles = try service.fetchArticles(for: feed2)
        
        #expect(feed1Articles.isEmpty)
        #expect(feed2Articles.count == 3)
    }
    
    @Test func markAllArticlesAsReadForFeed() async throws {
        let (_, service) = createTestStack()
        
        let feed = try service.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        for i in 1...3 {
            _ = try service.createArticle(
                title: "Article \(i)",
                content: nil,
                summary: nil,
                author: nil,
                publishedDate: Date(),
                url: nil,
                feed: feed
            )
        }
        
        try service.markAllArticlesAsRead(for: feed)
        
        // Wait a bit for background operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let unreadCount = try service.getUnreadCount(for: feed)
        #expect(unreadCount == 0)
    }
    
    // MARK: - Statistics Tests
    
    @Test func getUnreadCount() async throws {
        let (_, service) = createTestStack()
        
        let feed = try service.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        for i in 1...5 {
            let article = try service.createArticle(
                title: "Article \(i)",
                content: nil,
                summary: nil,
                author: nil,
                publishedDate: Date(),
                url: nil,
                feed: feed
            )
            if i <= 2 {
                try service.markArticleAsRead(article)
            }
        }
        
        let feedUnreadCount = try service.getUnreadCount(for: feed)
        #expect(feedUnreadCount == 3)
        
        let totalUnreadCount = try service.getUnreadCount()
        #expect(totalUnreadCount == 3)
    }
    
    @Test func getTotalArticleCount() async throws {
        let (_, service) = createTestStack()
        
        let feed = try service.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        for i in 1...5 {
            _ = try service.createArticle(
                title: "Article \(i)",
                content: nil,
                summary: nil,
                author: nil,
                publishedDate: Date(),
                url: nil,
                feed: feed
            )
        }
        
        let feedArticleCount = try service.getTotalArticleCount(for: feed)
        #expect(feedArticleCount == 5)
        
        let totalArticleCount = try service.getTotalArticleCount()
        #expect(totalArticleCount == 5)
    }
    
    // MARK: - Background Operations Tests
    
    @Test func importArticlesWithDuplicateDetection() async throws {
        let (_, service) = createTestStack()
        
        let feed = try service.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        let existingArticle = try service.createArticle(
            title: "Existing Article",
            content: nil,
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: URL(string: "https://example.com/article1"),
            feed: feed
        )
        
        let parsedArticles = [
            (title: "Existing Article", content: nil as String?, summary: nil as String?, author: nil as String?, publishedDate: Date(), url: URL(string: "https://example.com/article1")),
            (title: "New Article", content: nil as String?, summary: nil as String?, author: nil as String?, publishedDate: Date(), url: URL(string: "https://example.com/article2"))
        ]
        
        try await service.importArticles(from: parsedArticles, for: feed)
        
        let articles = try service.fetchArticles(for: feed)
        #expect(articles.count == 2)
        
        let titles = articles.map { $0.title }
        #expect(titles.contains("Existing Article"))
        #expect(titles.contains("New Article"))
        
        // Verify no duplicates were created
        let existingArticles = articles.filter { $0.title == "Existing Article" }
        #expect(existingArticles.count == 1)
        #expect(existingArticles.first?.id == existingArticle.id)
    }
    
    @Test func performBackgroundTaskSuccess() async throws {
        let (_, service) = createTestStack()
        
        let result = try await service.performBackgroundTask { context in
            return "Success"
        }
        
        #expect(result == "Success")
    }
    
    @Test func performBackgroundTaskError() async throws {
        let (_, service) = createTestStack()
        
        do {
            _ = try await service.performBackgroundTask { context in
                throw PersistenceError.invalidData
            }
            Issue.record("Expected error was not thrown")
        } catch PersistenceError.invalidData {
            // Expected error
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
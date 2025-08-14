import Testing
import Foundation
@testable import RSSium

struct PersistenceServiceBookmarkTests {
    
    // Create isolated test environment for each test to ensure 100% idempotency
    @MainActor
    private func createIsolatedTestStack() -> (PersistenceController, PersistenceService) {
        // Create a unique in-memory stack for each test to prevent conflicts
        let controller = PersistenceController(inMemory: true)
        let service = PersistenceService(persistenceController: controller)
        
        return (controller, service)
    }
    
    // Helper to create test data
    @MainActor
    private func createTestArticleWithFeed(persistenceService: PersistenceService) throws -> (Feed, Article) {
        let testURL = URL(string: "https://example.com/feed.xml")!
        let feed = try persistenceService.createFeed(title: "Test Feed", url: testURL)
        
        let article = try persistenceService.createArticle(
            title: "Test Article",
            content: "Test content",
            summary: "Test summary",
            author: "Test Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/article1"),
            feed: feed
        )
        
        return (feed, article)
    }
    
    @Test("Toggle bookmark should change isBookmarked property")
    @MainActor func toggleBookmarkProperty() async throws {
        let (_, persistenceService) = createIsolatedTestStack()
        
        let (_, article) = try createTestArticleWithFeed(persistenceService: persistenceService)
        
        // Initially not bookmarked
        #expect(article.isBookmarked == false)
        
        // Toggle to bookmarked
        try persistenceService.toggleBookmark(article)
        #expect(article.isBookmarked == true)
        
        // Toggle back to not bookmarked
        try persistenceService.toggleBookmark(article)
        #expect(article.isBookmarked == false)
    }
    
    @Test("Fetch bookmarked articles returns empty array initially")
    @MainActor func fetchBookmarkedArticlesEmpty() async throws {
        let (_, persistenceService) = createIsolatedTestStack()
        
        // Create non-bookmarked article
        let (_, _) = try createTestArticleWithFeed(persistenceService: persistenceService)
        
        let bookmarkedArticles = try persistenceService.fetchBookmarkedArticles()
        #expect(bookmarkedArticles.isEmpty)
    }
    
    @Test("Fetch bookmarked articles returns only bookmarked articles")
    @MainActor func fetchBookmarkedArticlesFiltered() async throws {
        let (_, persistenceService) = createIsolatedTestStack()
        
        let testURL = URL(string: "https://example.com/feed.xml")!
        let feed = try persistenceService.createFeed(title: "Test Feed", url: testURL)
        
        // Create multiple articles
        let article1 = try persistenceService.createArticle(
            title: "Article 1",
            content: "Content 1",
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: URL(string: "https://example.com/article1"),
            feed: feed
        )
        
        let article2 = try persistenceService.createArticle(
            title: "Article 2",
            content: "Content 2",
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: URL(string: "https://example.com/article2"),
            feed: feed
        )
        
        let article3 = try persistenceService.createArticle(
            title: "Article 3",
            content: "Content 3",
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: URL(string: "https://example.com/article3"),
            feed: feed
        )
        
        // Bookmark only article1 and article3
        try persistenceService.toggleBookmark(article1)
        try persistenceService.toggleBookmark(article3)
        
        let bookmarkedArticles = try persistenceService.fetchBookmarkedArticles()
        
        #expect(bookmarkedArticles.count == 2)
        
        let bookmarkedTitles = bookmarkedArticles.compactMap { $0.title }
        #expect(bookmarkedTitles.contains("Article 1"))
        #expect(bookmarkedTitles.contains("Article 3"))
        #expect(!bookmarkedTitles.contains("Article 2"))
    }
    
    @Test("Fetch bookmarked articles sorted by published date descending")
    @MainActor func fetchBookmarkedArticlesSorted() async throws {
        let (_, persistenceService) = createIsolatedTestStack()
        
        let testURL = URL(string: "https://example.com/feed.xml")!
        let feed = try persistenceService.createFeed(title: "Test Feed", url: testURL)
        
        // Create articles with different dates
        let olderDate = Date().addingTimeInterval(-86400) // 1 day ago
        let newerDate = Date()
        
        let olderArticle = try persistenceService.createArticle(
            title: "Older Article",
            content: "Older content",
            summary: nil,
            author: nil,
            publishedDate: olderDate,
            url: URL(string: "https://example.com/older"),
            feed: feed
        )
        
        let newerArticle = try persistenceService.createArticle(
            title: "Newer Article",
            content: "Newer content",
            summary: nil,
            author: nil,
            publishedDate: newerDate,
            url: URL(string: "https://example.com/newer"),
            feed: feed
        )
        
        // Bookmark both (bookmark older first, then newer)
        try persistenceService.toggleBookmark(olderArticle)
        try persistenceService.toggleBookmark(newerArticle)
        
        let bookmarkedArticles = try persistenceService.fetchBookmarkedArticles()
        
        #expect(bookmarkedArticles.count == 2)
        // Should be sorted by published date (newest first)
        #expect(bookmarkedArticles.first?.title == "Newer Article")
        #expect(bookmarkedArticles.last?.title == "Older Article")
    }
    
    @Test("Toggle bookmark persists changes to Core Data")
    @MainActor func toggleBookmarkPersistence() async throws {
        let (controller, persistenceService) = createIsolatedTestStack()
        
        let (_, article) = try createTestArticleWithFeed(persistenceService: persistenceService)
        
        // Toggle to bookmarked
        try persistenceService.toggleBookmark(article)
        
        // Verify persistence by creating a new context and fetching
        let context = controller.container.viewContext
        context.refreshAllObjects()
        
        let fetchedArticles = try persistenceService.fetchBookmarkedArticles()
        #expect(fetchedArticles.count == 1)
        #expect(fetchedArticles.first?.title == "Test Article")
        #expect(fetchedArticles.first?.isBookmarked == true)
    }
    
    @Test("Multiple toggle bookmark operations are idempotent")
    @MainActor func multipleToggleBookmarkIdempotent() async throws {
        let (_, persistenceService) = createIsolatedTestStack()
        
        let (_, article) = try createTestArticleWithFeed(persistenceService: persistenceService)
        
        // Initially not bookmarked
        #expect(article.isBookmarked == false)
        
        // Multiple toggles should be predictable
        try persistenceService.toggleBookmark(article) // true
        #expect(article.isBookmarked == true)
        
        try persistenceService.toggleBookmark(article) // false
        #expect(article.isBookmarked == false)
        
        try persistenceService.toggleBookmark(article) // true
        #expect(article.isBookmarked == true)
        
        try persistenceService.toggleBookmark(article) // false
        #expect(article.isBookmarked == false)
        
        // Final state should be consistent
        let bookmarkedArticles = try persistenceService.fetchBookmarkedArticles()
        #expect(bookmarkedArticles.isEmpty)
    }
}
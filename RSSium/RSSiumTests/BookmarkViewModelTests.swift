import Testing
import Foundation
@testable import RSSium

struct BookmarkViewModelTests {
    
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
    private func createTestArticleWithFeed(persistenceService: PersistenceService, isBookmarked: Bool = false) throws -> Article {
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
        
        if isBookmarked {
            try persistenceService.toggleBookmark(article)
        }
        
        return article
    }
    
    @Test("Initial state should be empty")
    @MainActor func initialState() async {
        let (_, persistenceService) = createIsolatedTestStack()
        
        let viewModel = BookmarkViewModel(persistenceService: persistenceService)
        
        #expect(viewModel.bookmarkedArticles.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.hasBookmarks == false)
        #expect(viewModel.bookmarkCount == 0)
    }
    
    @Test("Load bookmarked articles should populate array")
    @MainActor func loadBookmarkedArticles() async throws {
        let (_, persistenceService) = createIsolatedTestStack()
        
        // Create test articles - one bookmarked, one not
        _ = try createTestArticleWithFeed(persistenceService: persistenceService, isBookmarked: true)
        _ = try createTestArticleWithFeed(persistenceService: persistenceService, isBookmarked: false)
        
        let viewModel = BookmarkViewModel(persistenceService: persistenceService)
        
        #expect(viewModel.bookmarkedArticles.count == 1)
        #expect(viewModel.hasBookmarks == true)
        #expect(viewModel.bookmarkCount == 1)
        #expect(viewModel.bookmarkedArticles.first?.title == "Test Article")
    }
    
    @Test("Toggle bookmark should update bookmarked articles")
    @MainActor func toggleBookmark() async throws {
        let (_, persistenceService) = createIsolatedTestStack()
        
        let article = try createTestArticleWithFeed(persistenceService: persistenceService, isBookmarked: false)
        
        let viewModel = BookmarkViewModel(persistenceService: persistenceService)
        
        // Initially no bookmarks
        #expect(viewModel.bookmarkedArticles.isEmpty)
        
        // Add bookmark
        viewModel.toggleBookmark(for: article)
        
        // Should now have one bookmark
        #expect(viewModel.bookmarkedArticles.count == 1)
        #expect(viewModel.hasBookmarks == true)
        
        // Remove bookmark
        viewModel.toggleBookmark(for: article)
        
        // Should be empty again
        #expect(viewModel.bookmarkedArticles.isEmpty)
        #expect(viewModel.hasBookmarks == false)
    }
    
    @Test("Multiple bookmarked articles should be sorted by date")
    @MainActor func multipleBooksmarkedArticlesSorting() async throws {
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
        
        // Bookmark both
        try persistenceService.toggleBookmark(olderArticle)
        try persistenceService.toggleBookmark(newerArticle)
        
        let viewModel = BookmarkViewModel(persistenceService: persistenceService)
        
        #expect(viewModel.bookmarkedArticles.count == 2)
        // Should be sorted by published date (newest first)
        #expect(viewModel.bookmarkedArticles.first?.title == "Newer Article")
        #expect(viewModel.bookmarkedArticles.last?.title == "Older Article")
    }
    
    @Test("Clear error should reset error message")
    @MainActor func clearError() async {
        let (_, persistenceService) = createIsolatedTestStack()
        
        let viewModel = BookmarkViewModel(persistenceService: persistenceService)
        
        // Simulate an error
        viewModel.errorMessage = "Test error"
        #expect(viewModel.errorMessage == "Test error")
        
        // Clear error
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("Load bookmarked articles handles empty state correctly")
    @MainActor func loadBookmarkedArticlesEmptyState() async throws {
        let (_, persistenceService) = createIsolatedTestStack()
        
        // Create non-bookmarked article
        _ = try createTestArticleWithFeed(persistenceService: persistenceService, isBookmarked: false)
        
        let viewModel = BookmarkViewModel(persistenceService: persistenceService)
        
        #expect(viewModel.bookmarkedArticles.isEmpty)
        #expect(viewModel.hasBookmarks == false)
        #expect(viewModel.bookmarkCount == 0)
        #expect(viewModel.errorMessage == nil)
    }
}
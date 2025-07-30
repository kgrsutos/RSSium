import XCTest
import Testing
@testable import RSSium

struct FeedListViewModelTests {
    
    @Test("Initial state should be empty")
    func initialState() async {
        let persistenceService = PersistenceService(persistenceController: PersistenceController(inMemory: true))
        let viewModel = await FeedListViewModel(persistenceService: persistenceService)
        
        await MainActor.run {
            #expect(viewModel.feeds.isEmpty)
            #expect(viewModel.unreadCounts.isEmpty)
            #expect(viewModel.isLoading == false)
            #expect(viewModel.errorMessage == nil)
            #expect(viewModel.showingAddFeed == false)
        }
    }
    
    @Test("Load feeds should populate feeds array")
    func loadFeeds() async throws {
        let persistenceService = PersistenceService(persistenceController: PersistenceController(inMemory: true))
        
        let testURL = URL(string: "https://example.com/feed.xml")!
        let feed = try persistenceService.createFeed(title: "Test Feed", url: testURL)
        
        let viewModel = await FeedListViewModel(persistenceService: persistenceService)
        
        await MainActor.run {
            viewModel.loadFeeds()
            #expect(viewModel.feeds.count == 1)
            #expect(viewModel.feeds.first?.title == "Test Feed")
        }
    }
    
    @Test("Delete feed should remove feed from persistence")
    func deleteFeed() async throws {
        let persistenceService = PersistenceService(persistenceController: PersistenceController(inMemory: true))
        
        let testURL = URL(string: "https://example.com/feed.xml")!
        let feed = try persistenceService.createFeed(title: "Test Feed", url: testURL)
        
        let viewModel = await FeedListViewModel(persistenceService: persistenceService)
        
        await MainActor.run {
            viewModel.loadFeeds()
            #expect(viewModel.feeds.count == 1)
            
            viewModel.deleteFeed(feed)
            #expect(viewModel.feeds.isEmpty)
        }
        
        let remainingFeeds = try persistenceService.fetchAllFeeds()
        #expect(remainingFeeds.isEmpty)
    }
    
    @Test("Delete feeds at offsets should remove correct feeds")
    func deleteFeedsAtOffsets() async throws {
        let persistenceService = PersistenceService(persistenceController: PersistenceController(inMemory: true))
        
        let testURL1 = URL(string: "https://example1.com/feed.xml")!
        let testURL2 = URL(string: "https://example2.com/feed.xml")!
        let testURL3 = URL(string: "https://example3.com/feed.xml")!
        
        _ = try persistenceService.createFeed(title: "Feed 1", url: testURL1)
        _ = try persistenceService.createFeed(title: "Feed 2", url: testURL2)
        _ = try persistenceService.createFeed(title: "Feed 3", url: testURL3)
        
        let viewModel = await FeedListViewModel(persistenceService: persistenceService)
        
        await MainActor.run {
            viewModel.loadFeeds()
            #expect(viewModel.feeds.count == 3)
            
            let offsetsToDelete = IndexSet([0, 2])
            viewModel.deleteFeeds(at: offsetsToDelete)
            #expect(viewModel.feeds.count == 1)
            #expect(viewModel.feeds.first?.title == "Feed 2")
        }
    }
    
    @Test("Mark all as read should update unread counts")
    func markAllAsRead() async throws {
        let persistenceService = PersistenceService(persistenceController: PersistenceController(inMemory: true))
        
        let testURL = URL(string: "https://example.com/feed.xml")!
        let feed = try persistenceService.createFeed(title: "Test Feed", url: testURL)
        
        _ = try persistenceService.createArticle(
            title: "Test Article",
            content: nil,
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: nil,
            feed: feed
        )
        
        let viewModel = await FeedListViewModel(persistenceService: persistenceService)
        
        await MainActor.run {
            viewModel.loadFeeds()
            
            let initialUnreadCount = viewModel.getUnreadCount(for: feed)
            #expect(initialUnreadCount == 1)
            
            viewModel.markAllAsRead(for: feed)
            
            let finalUnreadCount = viewModel.getUnreadCount(for: feed)
            #expect(finalUnreadCount == 0)
        }
    }
    
    @Test("Get total unread count should sum all feeds")
    func getTotalUnreadCount() async throws {
        let persistenceService = PersistenceService(persistenceController: PersistenceController(inMemory: true))
        
        let testURL1 = URL(string: "https://example1.com/feed.xml")!
        let testURL2 = URL(string: "https://example2.com/feed.xml")!
        
        let feed1 = try persistenceService.createFeed(title: "Feed 1", url: testURL1)
        let feed2 = try persistenceService.createFeed(title: "Feed 2", url: testURL2)
        
        _ = try persistenceService.createArticle(
            title: "Article 1",
            content: nil,
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: nil,
            feed: feed1
        )
        
        _ = try persistenceService.createArticle(
            title: "Article 2",
            content: nil,
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: nil,
            feed: feed2
        )
        
        _ = try persistenceService.createArticle(
            title: "Article 3",
            content: nil,
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: nil,
            feed: feed2
        )
        
        let viewModel = await FeedListViewModel(persistenceService: persistenceService)
        
        await MainActor.run {
            viewModel.loadFeeds()
            
            let totalUnreadCount = viewModel.getTotalUnreadCount()
            #expect(totalUnreadCount == 3)
        }
    }
    
    @Test("Clear error should reset error message")
    func clearError() async {
        let persistenceService = PersistenceService(persistenceController: PersistenceController(inMemory: true))
        let viewModel = await FeedListViewModel(persistenceService: persistenceService)
        
        await MainActor.run {
            viewModel.errorMessage = "Test error"
            #expect(viewModel.errorMessage == "Test error")
            
            viewModel.clearError()
            #expect(viewModel.errorMessage == nil)
        }
    }
    
    @Test("Add feed with invalid URL should set error message")
    func addFeedWithInvalidURL() async {
        let persistenceService = PersistenceService(persistenceController: PersistenceController(inMemory: true))
        let viewModel = await FeedListViewModel(persistenceService: persistenceService)
        
        await viewModel.addFeed(url: "invalid-url")
        
        await MainActor.run {
            #expect(viewModel.errorMessage != nil)
            #expect(viewModel.errorMessage?.contains("Invalid URL format") == true)
        }
    }
    
    @Test("Add feed with empty URL should set error message")
    func addFeedWithEmptyURL() async {
        let persistenceService = PersistenceService(persistenceController: PersistenceController(inMemory: true))
        let viewModel = await FeedListViewModel(persistenceService: persistenceService)
        
        await viewModel.addFeed(url: "")
        
        await MainActor.run {
            #expect(viewModel.errorMessage != nil)
            #expect(viewModel.errorMessage?.contains("URL cannot be empty") == true)
        }
    }
}
import Testing
import Foundation
@testable import RSSium

struct FeedListViewModelTestsNew {
    
    // Create isolated test environment for each test
    @MainActor
    private func createIsolatedTestStack() -> (PersistenceController, PersistenceService, RSSService, RefreshService, NetworkMonitor) {
        // Create a unique in-memory stack for each test to prevent conflicts
        let controller = PersistenceController(inMemory: true)
        let service = PersistenceService(persistenceController: controller)
        
        // Use shared instances since they have private initializers
        let rssService = RSSService.shared
        let refreshService = RefreshService.shared
        let networkMonitor = NetworkMonitor.shared
        
        return (controller, service, rssService, refreshService, networkMonitor)
    }
    
    @Test("Initial state should be empty")
    @MainActor func initialState() async {
        let (_, persistenceService, rssService, refreshService, networkMonitor) = createIsolatedTestStack()
        
        let viewModel = FeedListViewModel(
            persistenceService: persistenceService, 
            rssService: rssService,
            refreshService: refreshService,
            networkMonitor: networkMonitor,
            autoLoadFeeds: false
        )
        
        #expect(viewModel.feeds.isEmpty)
        #expect(viewModel.unreadCounts.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showingAddFeed == false)
    }
    
    @Test("Load feeds should populate feeds array")
    @MainActor func loadFeeds() async throws {
        let (_, persistenceService, rssService, refreshService, networkMonitor) = createIsolatedTestStack()
        
        let testURL = URL(string: "https://example.com/feed.xml")!
        let feed = try persistenceService.createFeed(title: "Test Feed", url: testURL)
        
        let viewModel = FeedListViewModel(
            persistenceService: persistenceService, 
            rssService: rssService,
            refreshService: refreshService,
            networkMonitor: networkMonitor,
            autoLoadFeeds: false
        )
        
        viewModel.loadFeeds()
        
        #expect(viewModel.feeds.count == 1)
        #expect(viewModel.feeds.first?.title == "Test Feed")
    }
    
    @Test("Delete feed should remove feed from persistence")
    @MainActor func deleteFeed() async throws {
        let (_, persistenceService, rssService, refreshService, networkMonitor) = createIsolatedTestStack()
        
        let testURL = URL(string: "https://example.com/feed.xml")!
        let feed = try persistenceService.createFeed(title: "Test Feed", url: testURL)
        
        let viewModel = FeedListViewModel(
            persistenceService: persistenceService, 
            rssService: rssService,
            refreshService: refreshService,
            networkMonitor: networkMonitor,
            autoLoadFeeds: false
        )
        
        viewModel.loadFeeds()
        #expect(viewModel.feeds.count == 1)
        
        viewModel.deleteFeed(feed)
        #expect(viewModel.feeds.isEmpty)
        
        let remainingFeeds = try persistenceService.fetchAllFeeds()
        #expect(remainingFeeds.isEmpty)
    }
    
    @Test("Clear error should reset error message")
    @MainActor func clearError() async {
        let (_, persistenceService, rssService, refreshService, networkMonitor) = createIsolatedTestStack()
        
        let viewModel = FeedListViewModel(
            persistenceService: persistenceService, 
            rssService: rssService,
            refreshService: refreshService,
            networkMonitor: networkMonitor,
            autoLoadFeeds: false
        )
        
        viewModel.errorMessage = "Test error"
        #expect(viewModel.errorMessage == "Test error")
        
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("Add feed with empty URL should set error message")
    @MainActor func addFeedWithEmptyURL() async {
        let (_, persistenceService, rssService, refreshService, networkMonitor) = createIsolatedTestStack()
        
        let viewModel = FeedListViewModel(
            persistenceService: persistenceService, 
            rssService: rssService,
            refreshService: refreshService,
            networkMonitor: networkMonitor,
            autoLoadFeeds: false
        )
        
        await viewModel.addFeed(url: "")
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("URL cannot be empty") == true)
    }
    
    @Test("Add feed with invalid URL should set error message")
    @MainActor func addFeedWithInvalidURL() async {
        let (_, persistenceService, rssService, refreshService, networkMonitor) = createIsolatedTestStack()
        
        let viewModel = FeedListViewModel(
            persistenceService: persistenceService, 
            rssService: rssService,
            refreshService: refreshService,
            networkMonitor: networkMonitor,
            autoLoadFeeds: false
        )
        
        await viewModel.addFeed(url: "invalid-url")
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("Invalid URL format") == true)
    }
}
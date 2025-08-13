import Testing
import Foundation
@testable import RSSium

@MainActor
struct FeedListViewModelXCTests {
    
    // Create test services for isolated testing
    private func createTestServices() -> (PersistenceService, RSSService, RefreshService, NetworkMonitor) {
        let controller = PersistenceController(inMemory: true)
        let persistenceService = PersistenceService(persistenceController: controller)
        let rssService = RSSService.shared
        let refreshService = RefreshService.shared
        let networkMonitor = NetworkMonitor.shared
        return (persistenceService, rssService, refreshService, networkMonitor)
    }
    
    @Test("Initial state")
    func testInitialState() {
        let (persistenceService, rssService, refreshService, networkMonitor) = createTestServices()
        
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
    
    @Test("Load feeds")
    func testLoadFeeds() throws {
        let (persistenceService, rssService, refreshService, networkMonitor) = createTestServices()
        
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
    
    @Test("Delete feed")
    func testDeleteFeed() throws {
        let (persistenceService, rssService, refreshService, networkMonitor) = createTestServices()
        
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
    
    @Test("Clear error")
    func testClearError() {
        let (persistenceService, rssService, refreshService, networkMonitor) = createTestServices()
        
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
}
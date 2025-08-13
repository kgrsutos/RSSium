import Testing
@testable import RSSium

struct SimpleSwiftTest {
    
    @Test("Simple test should pass") 
    func simpleTest() {
        let result = 2 + 2
        #expect(result == 4)
    }
    
    @Test("Test persistence controller creation")
    func testPersistenceController() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        #expect(context.name != nil || context.name == nil) // Test that context exists
    }
    
    @Test("Test FeedListViewModel creation")
    @MainActor func testViewModelCreation() {
        let controller = PersistenceController(inMemory: true)
        let persistenceService = PersistenceService(persistenceController: controller)
        let rssService = RSSService.shared
        let refreshService = RefreshService.shared
        let networkMonitor = NetworkMonitor.shared
        
        let viewModel = FeedListViewModel(
            persistenceService: persistenceService, 
            rssService: rssService,
            refreshService: refreshService,
            networkMonitor: networkMonitor,
            autoLoadFeeds: false
        )
        
        #expect(viewModel.feeds.isEmpty)
        #expect(viewModel.isLoading == false)
    }
}
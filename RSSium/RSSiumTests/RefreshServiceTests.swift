import Testing
import CoreData
import Network
@testable import RSSium

@MainActor
struct RefreshServiceTests {
    
    private func createTestServices() -> PersistenceService {
        let controller = PersistenceController(inMemory: true)
        return PersistenceService(persistenceController: controller)
    }
    
    @Test("Refresh result processing")
    func testRefreshResultProcessing() throws {
        let persistenceService = createTestServices()
        
        // Create test feed
        let feedURL = URL(string: "https://example.com/feed.xml")!
        let feed = try persistenceService.createFeed(title: "Test Feed", url: feedURL)
        
        // Test refresh result creation
        let successResult = FeedRefreshResult(
            feed: feed,
            success: true,
            error: nil,
            newArticlesCount: 5
        )
        
        let failureResult = FeedRefreshResult(
            feed: feed,
            success: false,
            error: RefreshError.networkUnavailable,
            newArticlesCount: 0
        )
        
        #expect(successResult.isSuccess == true)
        #expect(failureResult.isSuccess == false)
        #expect(successResult.newArticlesCount == 5)
        #expect(failureResult.newArticlesCount == 0)
    }
    
    @Test("Refresh result aggregation")
    func testRefreshResultAggregation() throws {
        let persistenceService = createTestServices()
        
        // Create test feeds
        let feedURL1 = URL(string: "https://example.com/feed1.xml")!
        let feedURL2 = URL(string: "https://example.com/feed2.xml")!
        
        let feed1 = try persistenceService.createFeed(title: "Feed 1", url: feedURL1)
        let feed2 = try persistenceService.createFeed(title: "Feed 2", url: feedURL2)
        
        let results = [
            FeedRefreshResult(feed: feed1, success: true, error: nil, newArticlesCount: 3),
            FeedRefreshResult(feed: feed2, success: false, error: RefreshError.networkUnavailable, newArticlesCount: 0)
        ]
        
        let refreshResult = RefreshResult(
            totalFeeds: 2,
            successfulFeeds: 1,
            failedFeeds: 1,
            feedResults: results,
            totalNewArticles: 3
        )
        
        #expect(refreshResult.totalFeeds == 2)
        #expect(refreshResult.successfulFeeds == 1)
        #expect(refreshResult.failedFeeds == 1)
        #expect(refreshResult.totalNewArticles == 3)
        #expect(refreshResult.isCompleteSuccess == false)
        #expect(refreshResult.isPartialSuccess == true)
        #expect(refreshResult.isCompleteFailure == false)
    }
    
    @Test("Refresh error descriptions")
    func testRefreshErrorDescriptions() {
        let networkError = RefreshError.networkUnavailable
        let noFeedsError = RefreshError.noActiveFeeds
        let partialError = RefreshError.partialFailure(2, 5)
        let completeError = RefreshError.completeFailure("Test error")
        
        #expect(networkError.errorDescription == "Network connection is not available")
        #expect(noFeedsError.errorDescription == "No active feeds to refresh")
        #expect(partialError.errorDescription == "Failed to refresh 2 out of 5 feeds")
        #expect(completeError.errorDescription == "Refresh failed: Test error")
    }
    
    @Test("Singleton pattern")
    func testSingletonPattern() {
        let service1 = RefreshService.shared
        let service2 = RefreshService.shared
        #expect(service1 === service2)
    }
}

// MARK: - Mock Classes

class MockRSSService {
    var shouldSucceed = true
    var mockChannel: RSSChannel?
    
    func fetchAndParseFeed(from urlString: String) async throws -> RSSChannel {
        if shouldSucceed {
            return mockChannel ?? RSSChannel(title: "Mock Feed", link: urlString, description: "Mock Description", items: [])
        } else {
            throw RSSError.networkError(URLError(.notConnectedToInternet))
        }
    }
}

@MainActor
class MockNetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    var isWiFiConnected: Bool {
        isConnected && connectionType == .wifi
    }
    
    var isCellularConnected: Bool {
        isConnected && connectionType == .cellular
    }
}
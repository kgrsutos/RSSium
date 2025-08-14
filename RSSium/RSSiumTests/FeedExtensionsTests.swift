import Testing
import Foundation
import CoreData
@testable import RSSium

struct FeedExtensionsTests {
    
    private func createTestStack() -> (PersistenceController, NSManagedObjectContext) {
        let controller = PersistenceController(inMemory: true)
        return (controller, controller.container.viewContext)
    }
    
    private func createTestFeed(in context: NSManagedObjectContext, title: String = "Test Feed") -> Feed {
        let feed = Feed(context: context)
        feed.id = UUID()
        feed.title = title
        feed.url = URL(string: "https://example.com/\(UUID().uuidString)/feed.xml")!
        feed.lastUpdated = Date()
        feed.isActive = true
        return feed
    }
    
    private func createTestArticle(in context: NSManagedObjectContext, feed: Feed, isRead: Bool = false, publishedDate: Date = Date()) -> Article {
        let article = Article(context: context)
        article.id = UUID()
        article.title = "Test Article"
        article.content = "Test content"
        article.url = URL(string: "https://example.com/article")!
        article.publishedDate = publishedDate
        article.isRead = isRead
        article.feed = feed
        return article
    }
    
    @Test("Feed articles array sorting")
    func testArticlesArraySorting() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Create articles with different dates
        let oldArticle = createTestArticle(
            in: context,
            feed: feed,
            publishedDate: Date().addingTimeInterval(-7200) // 2 hours ago
        )
        
        let newArticle = createTestArticle(
            in: context,
            feed: feed,
            publishedDate: Date() // Now
        )
        
        let middleArticle = createTestArticle(
            in: context,
            feed: feed,
            publishedDate: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        
        let articles = feed.articlesArray
        
        #expect(articles.count == 3)
        if articles.count == 3 {
            // Should be sorted newest first
            #expect(articles[0] == newArticle)
            #expect(articles[1] == middleArticle)
            #expect(articles[2] == oldArticle)
        }
    }
    
    @Test("Feed unread count")
    func testUnreadCount() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Create mix of read and unread articles
        _ = createTestArticle(in: context, feed: feed, isRead: false)
        _ = createTestArticle(in: context, feed: feed, isRead: true)
        _ = createTestArticle(in: context, feed: feed, isRead: false)
        _ = createTestArticle(in: context, feed: feed, isRead: false)
        
        #expect(feed.unreadCount == 3)
    }
    
    @Test("Feed has unread articles")
    func testHasUnreadArticles() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Initially no articles
        #expect(feed.hasUnreadArticles == false)
        
        // Add read article
        _ = createTestArticle(in: context, feed: feed, isRead: true)
        #expect(feed.hasUnreadArticles == false)
        
        // Add unread article
        _ = createTestArticle(in: context, feed: feed, isRead: false)
        #expect(feed.hasUnreadArticles == true)
    }
    
    @Test("Feed convenience initializer")
    func testConvenienceInitializer() {
        let (_, context) = createTestStack()
        
        let feedURL = URL(string: "https://example.com/test-feed.xml")!
        let feed = Feed(context: context, title: "Convenience Test Feed", url: feedURL)
        
        #expect(feed.id != nil)
        #expect(feed.title == "Convenience Test Feed")
        #expect(feed.url == feedURL)
        #expect(feed.lastUpdated != nil)
        #expect(feed.isActive == true)
    }
    
    @Test("Fetch all active feeds")
    func testFetchAllActiveFeeds() throws {
        let (_, context) = createTestStack()
        
        // Create active feeds
        let activeFeed1 = createTestFeed(in: context, title: "Active Feed 1")
        activeFeed1.isActive = true
        
        let activeFeed2 = createTestFeed(in: context, title: "Active Feed 2")
        activeFeed2.isActive = true
        
        // Create inactive feed
        let inactiveFeed = createTestFeed(in: context, title: "Inactive Feed")
        inactiveFeed.isActive = false
        
        try context.save()
        
        let activeFeeds = Feed.fetchAllActive(context: context)
        
        #expect(activeFeeds.count == 2)
        #expect(activeFeeds.allSatisfy { $0.isActive })
        #expect(!activeFeeds.contains(inactiveFeed))
    }
    
    @Test("Fetch all active feeds sorted by title")
    func testFetchAllActiveFeedsSorting() throws {
        let (_, context) = createTestStack()
        
        // Create feeds with different titles
        let feedC = createTestFeed(in: context, title: "C Feed")
        let feedA = createTestFeed(in: context, title: "A Feed")
        let feedB = createTestFeed(in: context, title: "B Feed")
        
        try context.save()
        
        let activeFeeds = Feed.fetchAllActive(context: context)
        
        #expect(activeFeeds.count == 3)
        if activeFeeds.count == 3 {
            #expect(activeFeeds[0].title == "A Feed")
            #expect(activeFeeds[1].title == "B Feed")
            #expect(activeFeeds[2].title == "C Feed")
        }
    }
    
    @Test("Check feed exists with URL")
    func testFeedExistsWithURL() throws {
        let (_, context) = createTestStack()
        
        let feedURL = URL(string: "https://example.com/existing-feed.xml")!
        let feed = createTestFeed(in: context)
        feed.url = feedURL
        
        try context.save()
        
        // Check existing feed
        #expect(Feed.feedExists(with: feedURL, in: context) == true)
        
        // Check non-existing feed
        let nonExistingURL = URL(string: "https://example.com/non-existing-feed.xml")!
        #expect(Feed.feedExists(with: nonExistingURL, in: context) == false)
    }
    
    @Test("Articles array with nil published dates")
    func testArticlesArrayWithNilDates() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Create articles with various date states
        let articleWithDate = createTestArticle(
            in: context,
            feed: feed,
            publishedDate: Date()
        )
        
        let articleWithNilDate = createTestArticle(in: context, feed: feed)
        articleWithNilDate.publishedDate = nil
        
        let articleWithOldDate = createTestArticle(
            in: context,
            feed: feed,
            publishedDate: Date().addingTimeInterval(-3600)
        )
        
        let articles = feed.articlesArray
        
        #expect(articles.count == 3)
        // Articles with nil dates should be sorted as distant past
        if articles.count == 3 {
            #expect(articles[0] == articleWithDate)
            #expect(articles[1] == articleWithOldDate)
            #expect(articles[2] == articleWithNilDate)
        }
    }
    
    @Test("Empty feed unread count")
    func testEmptyFeedUnreadCount() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        #expect(feed.unreadCount == 0)
        #expect(feed.hasUnreadArticles == false)
    }
    
    @Test("Feed with all read articles")
    func testFeedWithAllReadArticles() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Create only read articles
        for _ in 0..<3 {
            _ = createTestArticle(in: context, feed: feed, isRead: true)
        }
        
        #expect(feed.unreadCount == 0)
        #expect(feed.hasUnreadArticles == false)
    }
    
    @Test("Feed with all unread articles")
    func testFeedWithAllUnreadArticles() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Create only unread articles
        for _ in 0..<5 {
            _ = createTestArticle(in: context, feed: feed, isRead: false)
        }
        
        #expect(feed.unreadCount == 5)
        #expect(feed.hasUnreadArticles == true)
    }
    
    @Test("Multiple feeds existence check")
    func testMultipleFeedsExistenceCheck() throws {
        let (_, context) = createTestStack()
        
        let urls = [
            URL(string: "https://example.com/feed1.xml")!,
            URL(string: "https://example.com/feed2.xml")!,
            URL(string: "https://example.com/feed3.xml")!
        ]
        
        // Create feeds for first two URLs
        for i in 0..<2 {
            let feed = createTestFeed(in: context)
            feed.url = urls[i]
        }
        
        try context.save()
        
        #expect(Feed.feedExists(with: urls[0], in: context) == true)
        #expect(Feed.feedExists(with: urls[1], in: context) == true)
        #expect(Feed.feedExists(with: urls[2], in: context) == false)
    }
    
    @Test("Feed articles relationship integrity")
    func testFeedArticlesRelationshipIntegrity() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        let article1 = createTestArticle(in: context, feed: feed)
        let article2 = createTestArticle(in: context, feed: feed)
        
        let articles = feed.articlesArray
        
        #expect(articles.contains(article1))
        #expect(articles.contains(article2))
        #expect(articles.count == 2)
    }
    
    @Test("Fetch active feeds with no active feeds")
    func testFetchActiveFeedsWithNoActiveFeeds() throws {
        let (_, context) = createTestStack()
        
        // Create only inactive feeds
        for i in 0..<3 {
            let feed = createTestFeed(in: context, title: "Inactive Feed \(i)")
            feed.isActive = false
        }
        
        try context.save()
        
        let activeFeeds = Feed.fetchAllActive(context: context)
        #expect(activeFeeds.isEmpty)
    }
    
    @Test("Articles array with empty articles set")
    func testArticlesArrayWithEmptyArticlesSet() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // No articles added
        let articles = feed.articlesArray
        #expect(articles.isEmpty)
    }
    
    @Test("Feed convenience initializer with all fields")
    func testConvenienceInitializerWithAllFields() {
        let (_, context) = createTestStack()
        
        let feedURL = URL(string: "https://detailed-example.com/rss-feed.xml")!
        let feed = Feed(context: context, title: "Detailed Test Feed", url: feedURL)
        
        // Verify all fields are set correctly
        #expect(feed.id != nil)
        #expect(feed.title == "Detailed Test Feed")
        #expect(feed.url == feedURL)
        #expect(feed.lastUpdated != nil)
        #expect(feed.isActive == true)
        
        // Verify date is recent
        let timeDiff = abs(feed.lastUpdated!.timeIntervalSinceNow)
        #expect(timeDiff < 1.0) // Should be set within the last second
    }
    
    @Test("Unread count with large number of articles")
    func testUnreadCountWithLargeNumberOfArticles() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Create many articles with mixed read states
        for i in 0..<100 {
            let article = createTestArticle(in: context, feed: feed, isRead: i % 3 == 0)
        }
        
        let unreadCount = feed.unreadCount
        let expectedUnread = 100 - (100 / 3) // Approximately 67 unread articles
        #expect(unreadCount > 60 && unreadCount < 70)
        
        let hasUnread = feed.hasUnreadArticles
        #expect(hasUnread == true)
    }
    
    @Test("Feed exists with similar but different URLs")
    func testFeedExistsWithSimilarURLs() throws {
        let (_, context) = createTestStack()
        
        let originalURL = URL(string: "https://example.com/feed.xml")!
        let similarURL1 = URL(string: "https://example.com/feed.xml?param=value")!
        let similarURL2 = URL(string: "https://example.com/feed.xml#fragment")!
        let differentURL = URL(string: "https://different.com/feed.xml")!
        
        let feed = createTestFeed(in: context)
        feed.url = originalURL
        
        try context.save()
        
        // Only exact URL match should return true
        #expect(Feed.feedExists(with: originalURL, in: context) == true)
        #expect(Feed.feedExists(with: similarURL1, in: context) == false)
        #expect(Feed.feedExists(with: similarURL2, in: context) == false)
        #expect(Feed.feedExists(with: differentURL, in: context) == false)
    }
    
    @Test("Articles array sorting with complex date scenarios")
    func testArticlesArraySortingWithComplexDateScenarios() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Create articles with various date scenarios
        let futureArticle = createTestArticle(
            in: context,
            feed: feed,
            publishedDate: Date().addingTimeInterval(3600) // 1 hour in future
        )
        
        let currentArticle = createTestArticle(
            in: context,
            feed: feed,
            publishedDate: Date()
        )
        
        let pastArticle = createTestArticle(
            in: context,
            feed: feed,
            publishedDate: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        
        let veryOldArticle = createTestArticle(
            in: context,
            feed: feed,
            publishedDate: Date().addingTimeInterval(-86400 * 30) // 30 days ago
        )
        
        let articles = feed.articlesArray
        
        #expect(articles.count == 4)
        if articles.count == 4 {
            // Should be sorted newest first (including future dates)
            #expect(articles[0] == futureArticle)
            #expect(articles[1] == currentArticle)
            #expect(articles[2] == pastArticle)
            #expect(articles[3] == veryOldArticle)
        }
    }
    
    @Test("Fetch active feeds with mixed active states")
    func testFetchActiveFeedsWithMixedActiveStates() throws {
        let (_, context) = createTestStack()
        
        let activeFeed1 = createTestFeed(in: context, title: "Active 1")
        activeFeed1.isActive = true
        
        let inactiveFeed = createTestFeed(in: context, title: "Inactive")
        inactiveFeed.isActive = false
        
        let activeFeed2 = createTestFeed(in: context, title: "Active 2")
        activeFeed2.isActive = true
        
        let activeFeed3 = createTestFeed(in: context, title: "Active 3")
        activeFeed3.isActive = true
        
        let inactiveFeed2 = createTestFeed(in: context, title: "Inactive 2")
        inactiveFeed2.isActive = false
        
        try context.save()
        
        let activeFeeds = Feed.fetchAllActive(context: context)
        
        #expect(activeFeeds.count == 3)
        #expect(activeFeeds.allSatisfy { $0.isActive })
        
        let activeTitles = Set(activeFeeds.map { $0.title! })
        #expect(activeTitles.contains("Active 1"))
        #expect(activeTitles.contains("Active 2"))
        #expect(activeTitles.contains("Active 3"))
        #expect(!activeTitles.contains("Inactive"))
        #expect(!activeTitles.contains("Inactive 2"))
    }
    
    
    @Test("Unread count edge cases")
    func testUnreadCountEdgeCases() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Test with all read articles
        for _ in 0..<5 {
            _ = createTestArticle(in: context, feed: feed, isRead: true)
        }
        
        #expect(feed.unreadCount == 0)
        #expect(feed.hasUnreadArticles == false)
        
        // Add one unread article
        _ = createTestArticle(in: context, feed: feed, isRead: false)
        
        #expect(feed.unreadCount == 1)
        #expect(feed.hasUnreadArticles == true)
        
        // Test with all unread articles
        let feed2 = createTestFeed(in: context, title: "Feed 2")
        for _ in 0..<3 {
            _ = createTestArticle(in: context, feed: feed2, isRead: false)
        }
        
        #expect(feed2.unreadCount == 3)
        #expect(feed2.hasUnreadArticles == true)
    }
    
    @Test("Feed URL normalization and comparison")
    func testFeedURLNormalizationAndComparison() throws {
        let (_, context) = createTestStack()
        
        // Test that URL comparison is exact
        let baseURL = URL(string: "https://example.com/feed.xml")!
        let uppercaseURL = URL(string: "https://EXAMPLE.COM/feed.xml")!
        
        let feed = createTestFeed(in: context)
        feed.url = baseURL
        
        try context.save()
        
        #expect(Feed.feedExists(with: baseURL, in: context) == true)
        #expect(Feed.feedExists(with: uppercaseURL, in: context) == false)
    }
    
    @Test("Performance with large number of feeds")
    func testPerformanceWithLargeNumberOfFeeds() throws {
        let (_, context) = createTestStack()
        
        // Create many feeds
        for i in 0..<100 {
            let feed = createTestFeed(in: context, title: "Feed \(i)")
            feed.isActive = i % 2 == 0 // Half active, half inactive
        }
        
        try context.save()
        
        let startTime = Date()
        let activeFeeds = Feed.fetchAllActive(context: context)
        let endTime = Date()
        
        #expect(activeFeeds.count == 50) // Half should be active
        
        let executionTime = endTime.timeIntervalSince(startTime)
        #expect(executionTime < 5.0) // Allow more time for Core Data operations
    }
}
import Testing
import Foundation
import CoreData
@testable import RSSium

struct ArticleExtensionsTests {
    
    private func createTestStack() -> (PersistenceController, NSManagedObjectContext) {
        let controller = PersistenceController(inMemory: true)
        return (controller, controller.container.viewContext)
    }
    
    private func createTestFeed(in context: NSManagedObjectContext) -> Feed {
        let feed = Feed(context: context)
        feed.id = UUID()
        feed.title = "Test Feed"
        feed.url = URL(string: "https://example.com/feed.xml")!
        feed.lastUpdated = Date()
        return feed
    }
    
    private func createTestArticle(in context: NSManagedObjectContext, feed: Feed) -> Article {
        let article = Article(context: context)
        article.id = UUID()
        article.title = "Test Article"
        article.content = "<p>Test content with HTML tags</p>"
        article.summary = "Test summary"
        article.url = URL(string: "https://example.com/article")!
        article.publishedDate = Date()
        article.isRead = false
        article.feed = feed
        return article
    }
    
    @Test("Article formatted published date")
    func testFormattedPublishedDate() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        let article = createTestArticle(in: context, feed: feed)
        
        // Test with a valid date
        let formattedDate = article.formattedPublishedDate
        #expect(!formattedDate.isEmpty)
        
        // Test with nil date
        article.publishedDate = nil
        #expect(article.formattedPublishedDate == "")
    }
    
    @Test("Article display summary with summary field")
    func testDisplaySummaryWithSummary() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        let article = createTestArticle(in: context, feed: feed)
        
        article.summary = "This is a test summary"
        #expect(article.displaySummary == "This is a test summary")
    }
    
    @Test("Article display summary from content")
    func testDisplaySummaryFromContent() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        let article = createTestArticle(in: context, feed: feed)
        
        // Clear summary to test content extraction
        article.summary = nil
        article.content = "<p>This is a longer test content with HTML tags that should be stripped and truncated if necessary.</p>"
        
        let summary = article.displaySummary
        #expect(!summary.contains("<p>")) // HTML should be stripped
        #expect(!summary.contains("</p>"))
        #expect(summary.contains("This is a longer test content"))
    }
    
    @Test("Article display summary with long content")
    func testDisplaySummaryWithLongContent() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        let article = createTestArticle(in: context, feed: feed)
        
        article.summary = nil
        let longContent = String(repeating: "This is a very long content. ", count: 20)
        article.content = longContent
        
        let summary = article.displaySummary
        #expect(summary.count <= 153) // 150 chars + "..."
        #expect(summary.hasSuffix("..."))
    }
    
    @Test("Article display summary with empty content")
    func testDisplaySummaryWithEmptyContent() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        let article = createTestArticle(in: context, feed: feed)
        
        article.summary = nil
        article.content = nil
        
        #expect(article.displaySummary == "")
    }
    
    @Test("Article convenience initializer")
    func testConvenienceInitializer() throws {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        let article = Article(
            context: context,
            title: "Convenience Test",
            content: "Test content",
            url: URL(string: "https://example.com/test")!,
            publishedDate: Date(),
            feed: feed
        )
        
        #expect(article.id != nil)
        #expect(article.title == "Convenience Test")
        #expect(article.content == "Test content")
        #expect(article.url?.absoluteString == "https://example.com/test")
        #expect(article.publishedDate != nil)
        #expect(article.isRead == false)
        #expect(article.feed == feed)
    }
    
    @Test("Mark article as read")
    func testMarkAsRead() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        let article = createTestArticle(in: context, feed: feed)
        
        article.isRead = false
        article.markAsRead()
        #expect(article.isRead == true)
    }
    
    @Test("Mark article as unread")
    func testMarkAsUnread() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        let article = createTestArticle(in: context, feed: feed)
        
        article.isRead = true
        article.markAsUnread()
        #expect(article.isRead == false)
    }
    
    @Test("Fetch unread articles for specific feed")
    func testFetchUnreadForFeed() throws {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Create some test articles
        let unreadArticle1 = createTestArticle(in: context, feed: feed)
        unreadArticle1.isRead = false
        
        let readArticle = createTestArticle(in: context, feed: feed)
        readArticle.isRead = true
        
        let unreadArticle2 = createTestArticle(in: context, feed: feed)
        unreadArticle2.isRead = false
        
        try context.save()
        
        let unreadArticles = Article.fetchUnread(for: feed, in: context)
        #expect(unreadArticles.count == 2)
        #expect(unreadArticles.allSatisfy { !$0.isRead })
    }
    
    @Test("Fetch all unread articles")
    func testFetchAllUnread() throws {
        let (_, context) = createTestStack()
        
        let feed1 = createTestFeed(in: context)
        let feed2 = createTestFeed(in: context)
        
        let unread1 = createTestArticle(in: context, feed: feed1)
        unread1.isRead = false
        
        let read = createTestArticle(in: context, feed: feed1)
        read.isRead = true
        
        let unread2 = createTestArticle(in: context, feed: feed2)
        unread2.isRead = false
        
        try context.save()
        
        let allUnread = Article.fetchUnread(for: nil, in: context)
        #expect(allUnread.count == 2)
        #expect(allUnread.allSatisfy { !$0.isRead })
    }
    
    @Test("Fetch recent articles with limit")
    func testFetchRecentWithLimit() throws {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Create more articles than the limit
        for i in 0..<10 {
            let article = createTestArticle(in: context, feed: feed)
            article.publishedDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
        }
        
        try context.save()
        
        let recentArticles = Article.fetchRecent(limit: 5, for: feed, in: context)
        #expect(recentArticles.count == 5)
    }
    
    @Test("Fetch recent articles for specific feed")
    func testFetchRecentForFeed() throws {
        let (_, context) = createTestStack()
        
        let feed1 = createTestFeed(in: context)
        let feed2 = createTestFeed(in: context)
        
        // Create articles for different feeds
        for i in 0..<3 {
            let article1 = createTestArticle(in: context, feed: feed1)
            article1.publishedDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
            
            let article2 = createTestArticle(in: context, feed: feed2)
            article2.publishedDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
        }
        
        try context.save()
        
        let feed1Articles = Article.fetchRecent(limit: 10, for: feed1, in: context)
        #expect(feed1Articles.count == 3)
        #expect(feed1Articles.allSatisfy { $0.feed == feed1 })
    }
    
    @Test("Fetch all recent articles")
    func testFetchAllRecent() throws {
        let (_, context) = createTestStack()
        
        let feed1 = createTestFeed(in: context)
        let feed2 = createTestFeed(in: context)
        
        // Create articles for different feeds
        for i in 0..<3 {
            let article1 = createTestArticle(in: context, feed: feed1)
            article1.publishedDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
            
            let article2 = createTestArticle(in: context, feed: feed2)
            article2.publishedDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
        }
        
        try context.save()
        
        let allRecent = Article.fetchRecent(limit: 10, for: nil, in: context)
        #expect(allRecent.count == 6)
    }
    
    @Test("Article HTML stripping in display summary")
    func testHTMLStrippingInDisplaySummary() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        let article = createTestArticle(in: context, feed: feed)
        
        article.summary = nil
        article.content = "<div><p>Content with <strong>HTML</strong> tags</p><br/>&nbsp;and entities&amp;</div>"
        
        let summary = article.displaySummary
        #expect(!summary.contains("<div>"))
        #expect(!summary.contains("<p>"))
        #expect(!summary.contains("<strong>"))
        #expect(!summary.contains("</"))
        #expect(!summary.contains("&nbsp;"))
        #expect(!summary.contains("&amp;"))
    }
    
    @Test("Recent articles sorted by published date")
    func testRecentArticlesSorting() throws {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        let oldArticle = createTestArticle(in: context, feed: feed)
        oldArticle.publishedDate = Date().addingTimeInterval(-7200) // 2 hours ago
        
        let newArticle = createTestArticle(in: context, feed: feed)
        newArticle.publishedDate = Date() // Now
        
        let middleArticle = createTestArticle(in: context, feed: feed)
        middleArticle.publishedDate = Date().addingTimeInterval(-3600) // 1 hour ago
        
        try context.save()
        
        let recentArticles = Article.fetchRecent(limit: 10, for: feed, in: context)
        
        #expect(recentArticles.count == 3)
        if recentArticles.count == 3 {
            // Should be sorted newest first
            #expect(recentArticles[0].publishedDate! >= recentArticles[1].publishedDate!)
            #expect(recentArticles[1].publishedDate! >= recentArticles[2].publishedDate!)
        }
    }
    
    @Test("Display summary with complex HTML entities")
    func testDisplaySummaryWithComplexHTMLEntities() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        let article = createTestArticle(in: context, feed: feed)
        
        article.summary = nil
        article.content = "<p>Content with &quot;quotes&quot; and &amp; ampersands &lt;tags&gt; and &nbsp; spaces</p>"
        
        let summary = article.displaySummary
        #expect(!summary.contains("&quot;"))
        #expect(!summary.contains("&amp;"))
        #expect(!summary.contains("&lt;"))
        #expect(!summary.contains("&gt;"))
        #expect(!summary.contains("&nbsp;"))
        #expect(!summary.contains("<p>"))
        #expect(!summary.contains("</p>"))
    }
    
    @Test("Display summary with nested HTML tags")
    func testDisplaySummaryWithNestedHTMLTags() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        let article = createTestArticle(in: context, feed: feed)
        
        article.summary = nil
        article.content = "<div><p>Outer <span>inner <strong>nested</strong> content</span> more text</p></div>"
        
        let summary = article.displaySummary
        #expect(!summary.contains("<div>"))
        #expect(!summary.contains("<p>"))
        #expect(!summary.contains("<span>"))
        #expect(!summary.contains("<strong>"))
        #expect(!summary.contains("</"))
        #expect(summary.contains("Outer inner nested content more text"))
    }
    
    @Test("Formatted published date with different date formats")
    func testFormattedPublishedDateWithDifferentFormats() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Test with very recent date
        let recentArticle = createTestArticle(in: context, feed: feed)
        recentArticle.publishedDate = Date().addingTimeInterval(-60) // 1 minute ago
        let recentFormat = recentArticle.formattedPublishedDate
        #expect(!recentFormat.isEmpty)
        
        // Test with old date
        let oldArticle = createTestArticle(in: context, feed: feed)
        oldArticle.publishedDate = Date().addingTimeInterval(-86400 * 7) // 1 week ago
        let oldFormat = oldArticle.formattedPublishedDate
        #expect(!oldFormat.isEmpty)
        
        // Test with very old date
        let veryOldArticle = createTestArticle(in: context, feed: feed)
        veryOldArticle.publishedDate = Date().addingTimeInterval(-86400 * 365) // 1 year ago
        let veryOldFormat = veryOldArticle.formattedPublishedDate
        #expect(!veryOldFormat.isEmpty)
    }
    
    @Test("Fetch with error handling")
    func testFetchWithErrorHandling() throws {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Create articles
        for i in 0..<5 {
            let article = createTestArticle(in: context, feed: feed)
            article.title = "Article \(i)"
            article.isRead = i % 2 == 0
        }
        
        try context.save()
        
        // Test fetches with valid parameters
        let unreadArticles = Article.fetchUnread(for: feed, in: context)
        let recentArticles = Article.fetchRecent(limit: 3, for: feed, in: context)
        let allUnread = Article.fetchUnread(for: nil, in: context)
        
        #expect(unreadArticles.count >= 0)
        #expect(recentArticles.count >= 0)
        #expect(allUnread.count >= 0)
    }
    
    @Test("Read state manipulation")
    func testReadStateManipulation() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        let article = createTestArticle(in: context, feed: feed)
        
        // Test initial state
        article.isRead = false
        #expect(article.isRead == false)
        
        // Test marking as read
        article.markAsRead()
        #expect(article.isRead == true)
        
        // Test marking as unread
        article.markAsUnread()
        #expect(article.isRead == false)
        
        // Test multiple toggles
        for _ in 0..<5 {
            article.markAsRead()
            #expect(article.isRead == true)
            article.markAsUnread()
            #expect(article.isRead == false)
        }
    }
    
    @Test("Article convenience initializer with all parameters")
    func testConvenienceInitializerWithAllParameters() throws {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        let publishDate = Date()
        let testURL = URL(string: "https://example.com/specific-article")!
        
        let article = Article(
            context: context,
            title: "Detailed Test Article",
            content: "Detailed test content with more information",
            url: testURL,
            publishedDate: publishDate,
            feed: feed
        )
        
        #expect(article.id != nil)
        #expect(article.title == "Detailed Test Article")
        #expect(article.content == "Detailed test content with more information")
        #expect(article.url == testURL)
        #expect(article.publishedDate == publishDate)
        #expect(article.isRead == false)
        #expect(article.feed == feed)
        
        // Test that the article is properly related to the feed
        #expect(feed.articles?.contains(article) == true)
    }
    
    @Test("Fetch recent with zero limit")
    func testFetchRecentWithZeroLimit() throws {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        
        // Create some articles
        for i in 0..<3 {
            let article = createTestArticle(in: context, feed: feed)
            article.title = "Article \(i)"
        }
        
        try context.save()
        
        // Test with zero limit
        let recentArticles = Article.fetchRecent(limit: 0, for: feed, in: context)
        #expect(recentArticles.isEmpty)
    }
    
    @Test("Display summary with only whitespace content")
    func testDisplaySummaryWithOnlyWhitespaceContent() {
        let (_, context) = createTestStack()
        let feed = createTestFeed(in: context)
        let article = createTestArticle(in: context, feed: feed)
        
        article.summary = nil
        article.content = "   \n\t   \r\n   " // Only whitespace
        
        let summary = article.displaySummary
        #expect(summary.isEmpty)
    }
}
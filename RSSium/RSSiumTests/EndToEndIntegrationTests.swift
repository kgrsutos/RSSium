import Testing
import Foundation
import CoreData
@testable import RSSium

@MainActor
struct EndToEndIntegrationTests {
    
    private func createIsolatedTestStack() -> (PersistenceController, PersistenceService, RSSService) {
        let controller = PersistenceController(inMemory: true)
        let service = PersistenceService(persistenceController: controller)
        let rssService = RSSService.shared
        return (controller, service, rssService)
    }
    
    @Test
    func fullFeedWorkflow() async throws {
        let (_, persistenceService, rssService) = createIsolatedTestStack()
        
        let feedURL = URL(string: "https://example.com/feed.xml")!
        let feed = try persistenceService.createFeed(title: "Test Feed", url: feedURL)
        
        let rssXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
        <channel>
            <title>Test RSS Feed</title>
            <link>https://example.com</link>
            <description>Test Description</description>
            <item>
                <title>Breaking News</title>
                <link>https://example.com/breaking</link>
                <description>Important news article</description>
                <pubDate>Mon, 01 Jan 2024 12:00:00 GMT</pubDate>
            </item>
            <item>
                <title>Tech Review</title>
                <link>https://example.com/tech</link>
                <description>Latest technology review</description>
                <pubDate>Sun, 31 Dec 2023 18:00:00 GMT</pubDate>
            </item>
        </channel>
        </rss>
        """
        
        let data = Data(rssXML.utf8)
        let channel = try rssService.parseData(data)
        
        // Convert RSSItems to the expected tuple format
        let articleTuples = channel.items.map { item in
            (
                title: item.title,
                content: item.description,
                summary: item.description,
                author: item.author,
                publishedDate: item.pubDate ?? Date(),
                url: item.link.flatMap { URL(string: $0) }
            )
        }
        try await persistenceService.importArticles(from: articleTuples, for: feed)
        
        let articles = try persistenceService.fetchArticles(for: feed)
        #expect(articles.count == 2)
        
        let unreadCount = try persistenceService.getUnreadCount(for: feed)
        #expect(unreadCount == 2)
        
        guard let firstArticle = articles.first else {
            #expect(Bool(false))
            return
        }
        
        try persistenceService.markArticleAsRead(firstArticle)
        
        let updatedUnreadCount = try persistenceService.getUnreadCount(for: feed)
        #expect(updatedUnreadCount == 1)
        
        let readArticles = try persistenceService.fetchArticles(for: feed).filter { $0.isRead }
        #expect(readArticles.count == 1)
        
        let unreadArticles = try persistenceService.fetchArticles(for: feed).filter { !$0.isRead }
        #expect(unreadArticles.count == 1)
    }
    
    @Test
    func batchOperationsIntegration() async throws {
        let (_, persistenceService, _) = createIsolatedTestStack()
        
        let feed1 = try persistenceService.createFeed(title: "Feed 1", url: URL(string: "https://example.com/1")!)
        let feed2 = try persistenceService.createFeed(title: "Feed 2", url: URL(string: "https://example.com/2")!)
        
        let articles1 = [
            RSSItem(title: "Article 1", link: "https://example.com/1/1", description: "Content 1", pubDate: Date(), author: nil, guid: nil),
            RSSItem(title: "Article 2", link: "https://example.com/1/2", description: "Content 2", pubDate: Date(), author: nil, guid: nil)
        ]
        
        let articles2 = [
            RSSItem(title: "Article 3", link: "https://example.com/2/1", description: "Content 3", pubDate: Date(), author: nil, guid: nil),
            RSSItem(title: "Article 4", link: "https://example.com/2/2", description: "Content 4", pubDate: Date(), author: nil, guid: nil),
            RSSItem(title: "Article 5", link: "https://example.com/2/3", description: "Content 5", pubDate: Date(), author: nil, guid: nil)
        ]
        
        let articleTuples1 = articles1.map { item in
            (title: item.title, content: item.description, summary: item.description, author: item.author, publishedDate: item.pubDate ?? Date(), url: item.link.flatMap { URL(string: $0) })
        }
        let articleTuples2 = articles2.map { item in
            (title: item.title, content: item.description, summary: item.description, author: item.author, publishedDate: item.pubDate ?? Date(), url: item.link.flatMap { URL(string: $0) })
        }
        
        try await persistenceService.importArticles(from: articleTuples1, for: feed1)
        try await persistenceService.importArticles(from: articleTuples2, for: feed2)
        
        let totalCount = try persistenceService.getTotalArticleCount()
        #expect(totalCount == 5)
        
        let feed1Articles = try persistenceService.fetchArticles(for: feed1)
        let feed2Articles = try persistenceService.fetchArticles(for: feed2)
        
        #expect(feed1Articles.count == 2)
        #expect(feed2Articles.count == 3)
        
        try persistenceService.markAllArticlesAsRead(for: feed1)
        
        let feed1UnreadCount = try persistenceService.getUnreadCount(for: feed1)
        let feed2UnreadCount = try persistenceService.getUnreadCount(for: feed2)
        
        #expect(feed1UnreadCount == 0)
        #expect(feed2UnreadCount == 3)
    }
    
    @Test
    func duplicateArticleHandling() async throws {
        let (_, persistenceService, _) = createIsolatedTestStack()
        
        let feed = try persistenceService.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed")!)
        
        let originalArticles = [
            RSSItem(title: "Article 1", link: "https://example.com/1", description: "Content 1", pubDate: Date(), author: nil, guid: nil),
            RSSItem(title: "Article 2", link: "https://example.com/2", description: "Content 2", pubDate: Date(), author: nil, guid: nil)
        ]
        
        let originalTuples = originalArticles.map { item in
            (title: item.title, content: item.description, summary: item.description, author: item.author, publishedDate: item.pubDate ?? Date(), url: item.link.flatMap { URL(string: $0) })
        }
        try await persistenceService.importArticles(from: originalTuples, for: feed)
        
        let initialCount = try persistenceService.fetchArticles(for: feed).count
        #expect(initialCount == 2)
        
        let duplicateArticles = [
            RSSItem(title: "Article 1", link: "https://example.com/1", description: "Content 1", pubDate: Date(), author: nil, guid: nil),
            RSSItem(title: "Article 3", link: "https://example.com/3", description: "Content 3", pubDate: Date(), author: nil, guid: nil)
        ]
        
        let duplicateTuples = duplicateArticles.map { item in
            (title: item.title, content: item.description, summary: item.description, author: item.author, publishedDate: item.pubDate ?? Date(), url: item.link.flatMap { URL(string: $0) })
        }
        try await persistenceService.importArticles(from: duplicateTuples, for: feed)
        
        let finalCount = try persistenceService.fetchArticles(for: feed).count
        #expect(finalCount == 3)
        
        let articles = try persistenceService.fetchArticles(for: feed)
        let titles = articles.compactMap { $0.title }.sorted()
        #expect(titles == ["Article 1", "Article 2", "Article 3"])
    }
    
    @Test
    func feedUpdateWorkflow() async throws {
        let (_, persistenceService, _) = createIsolatedTestStack()
        
        let feedURL = URL(string: "https://example.com/news")!
        let feed = try persistenceService.createFeed(title: "News Feed", url: feedURL)
        
        #expect(feed.lastUpdated != nil) // Feed should have lastUpdated set on creation
        
        let initialArticles = [
            RSSItem(title: "Old News", link: "https://example.com/old", description: "Old content", pubDate: Date(), author: nil, guid: nil)
        ]
        
        let initialTuples = initialArticles.map { item in
            (title: item.title, content: item.description, summary: item.description, author: item.author, publishedDate: item.pubDate ?? Date(), url: item.link.flatMap { URL(string: $0) })
        }
        try await persistenceService.importArticles(from: initialTuples, for: feed)
        // Update feed's last updated timestamp
        feed.lastUpdated = Date()
        try persistenceService.updateFeed(feed)
        
        #expect(feed.lastUpdated != nil)
        
        let newArticles = [
            RSSItem(title: "Breaking News", link: "https://example.com/breaking", description: "Fresh content", pubDate: Date(), author: nil, guid: nil)
        ]
        
        let newTuples = newArticles.map { item in
            (title: item.title, content: item.description, summary: item.description, author: item.author, publishedDate: item.pubDate ?? Date(), url: item.link.flatMap { URL(string: $0) })
        }
        try await persistenceService.importArticles(from: newTuples, for: feed)
        
        let allArticles = try persistenceService.fetchArticles(for: feed)
        #expect(allArticles.count == 2)
        
        let sortedArticles = allArticles.sorted { $0.publishedDate! > $1.publishedDate! }
        #expect(sortedArticles.first?.title == "Breaking News")
    }
}
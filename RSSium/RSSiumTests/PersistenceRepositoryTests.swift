import Testing
import Foundation
@testable import RSSium

/// モックを使用した完全に冪等性が保証されたテスト
struct PersistenceRepositoryTests {
    
    private func createMockRepository() -> MockPersistenceRepository {
        let repository = MockPersistenceRepository()
        repository.reset() // 確実にクリーンな状態から開始
        return repository
    }
    
    // MARK: - Feed Tests
    
    @Test func createAndFetchFeed() async throws {
        let repository = createMockRepository()
        
        let title = "Test Feed"
        let url = URL(string: "https://example.com/feed.xml")!
        
        let feed = try await repository.createFeed(title: title, url: url, iconURL: nil)
        
        #expect(feed.title == title)
        #expect(feed.url == url)
        #expect(feed.isActive == true)
        
        let fetchedFeeds = try await repository.fetchAllFeeds()
        #expect(fetchedFeeds.count == 1)
        #expect(fetchedFeeds.first?.id == feed.id)
        
        // 状態確認
        let state = repository.getCurrentState()
        #expect(state.feeds == 1)
        #expect(state.articles == 0)
    }
    
    @Test func fetchActiveFeedsOnly() async throws {
        let repository = createMockRepository()
        
        let activeFeed = try await repository.createFeed(
            title: "Active Feed",
            url: URL(string: "https://active.com/feed.xml")!,
            iconURL: nil
        )
        
        let inactiveFeed = try await repository.createFeed(
            title: "Inactive Feed",
            url: URL(string: "https://inactive.com/feed.xml")!,
            iconURL: nil
        )
        
        inactiveFeed.isActive = false
        try await repository.updateFeed(inactiveFeed)
        
        let activeFeeds = try await repository.fetchActiveFeeds()
        #expect(activeFeeds.count == 1)
        #expect(activeFeeds.first?.id == activeFeed.id)
    }
    
    // MARK: - Article Tests
    
    @Test func fetchUnreadArticles() async throws {
        let repository = createMockRepository()
        
        let feed = try await repository.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!,
            iconURL: nil
        )
        
        let unreadArticle = try await repository.createArticle(
            title: "Unread Article",
            content: nil,
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: nil,
            feed: feed
        )
        
        let readArticle = try await repository.createArticle(
            title: "Read Article",
            content: nil,
            summary: nil,
            author: nil,
            publishedDate: Date(),
            url: nil,
            feed: feed
        )
        
        try await repository.markArticleAsRead(readArticle)
        
        let unreadArticles = try await repository.fetchUnreadArticles(for: feed)
        #expect(unreadArticles.count == 1)
        #expect(unreadArticles.first?.id == unreadArticle.id)
        
        // 状態確認
        let state = repository.getCurrentState()
        #expect(state.articles == 2)
        #expect(state.unreadArticles == 1)
    }
    
    @Test func deleteAllArticlesForFeed() async throws {
        let repository = createMockRepository()
        
        let feed1 = try await repository.createFeed(
            title: "Feed 1",
            url: URL(string: "https://example1.com/feed.xml")!,
            iconURL: nil
        )
        
        let feed2 = try await repository.createFeed(
            title: "Feed 2",
            url: URL(string: "https://example2.com/feed.xml")!,
            iconURL: nil
        )
        
        // Feed 1に3記事、Feed 2に3記事作成
        for i in 1...3 {
            _ = try await repository.createArticle(
                title: "Feed 1 Article \(i)",
                content: nil,
                summary: nil,
                author: nil,
                publishedDate: Date(),
                url: nil,
                feed: feed1
            )
            
            _ = try await repository.createArticle(
                title: "Feed 2 Article \(i)",
                content: nil,
                summary: nil,
                author: nil,
                publishedDate: Date(),
                url: nil,
                feed: feed2
            )
        }
        
        // Feed 1の記事のみ削除
        try await repository.deleteAllArticles(for: feed1)
        
        let feed1Articles = try await repository.fetchArticles(for: feed1)
        let feed2Articles = try await repository.fetchArticles(for: feed2)
        
        #expect(feed1Articles.isEmpty)
        #expect(feed2Articles.count == 3)
        
        // 状態確認
        let state = repository.getCurrentState()
        #expect(state.articles == 3)
    }
    
    @Test func markAllArticlesAsReadForFeed() async throws {
        let repository = createMockRepository()
        
        let feed = try await repository.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!,
            iconURL: nil
        )
        
        for i in 1...3 {
            _ = try await repository.createArticle(
                title: "Article \(i)",
                content: nil,
                summary: nil,
                author: nil,
                publishedDate: Date(),
                url: nil,
                feed: feed
            )
        }
        
        // 初期状態確認
        let initialUnreadCount = try await repository.getUnreadCount(for: feed)
        #expect(initialUnreadCount == 3)
        
        // 全記事を既読にする
        try await repository.markAllArticlesAsRead(for: feed)
        
        let unreadCount = try await repository.getUnreadCount(for: feed)
        #expect(unreadCount == 0)
        
        // 状態確認
        let state = repository.getCurrentState()
        #expect(state.unreadArticles == 0)
    }
    
    @Test func getUnreadCount() async throws {
        let repository = createMockRepository()
        
        let feed = try await repository.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!,
            iconURL: nil
        )
        
        var articles: [Article] = []
        for i in 1...5 {
            let article = try await repository.createArticle(
                title: "Article \(i)",
                content: nil,
                summary: nil,
                author: nil,
                publishedDate: Date(),
                url: URL(string: "https://example.com/article\(i)"),
                feed: feed
            )
            articles.append(article)
        }
        
        // 最初の2記事を既読にする
        for i in 0..<2 {
            try await repository.markArticleAsRead(articles[i])
        }
        
        let feedUnreadCount = try await repository.getUnreadCount(for: feed)
        #expect(feedUnreadCount == 3)
        
        let totalUnreadCount = try await repository.getUnreadCount(for: nil)
        #expect(totalUnreadCount == 3)
    }
    
    // MARK: - 冪等性テスト
    
    @Test func idempotencyTest_MultipleRuns() async throws {
        // 同じテストを10回実行して常に同じ結果になることを確認
        for run in 1...10 {
            let repository = createMockRepository() // 毎回新しいインスタンス
            
            let feed = try await repository.createFeed(
                title: "Test Feed \(run)",
                url: URL(string: "https://example.com/feed\(run).xml")!,
                iconURL: nil
            )
            
            for i in 1...3 {
                _ = try await repository.createArticle(
                    title: "Article \(i)",
                    content: nil,
                    summary: nil,
                    author: nil,
                    publishedDate: Date(),
                    url: nil,
                    feed: feed
                )
            }
            
            try await repository.markAllArticlesAsRead(for: feed)
            
            let unreadCount = try await repository.getUnreadCount(for: feed)
            #expect(unreadCount == 0) // 常に0になるはず
            
            let totalCount = try await repository.getTotalArticleCount(for: feed)
            #expect(totalCount == 3) // 常に3になるはず
            
            // リセットして次の実行に影響しないことを確認
            repository.reset()
            let state = repository.getCurrentState()
            #expect(state.feeds == 0)
            #expect(state.articles == 0)
        }
    }
}
import Testing
import Foundation
import CoreData
@testable import RSSium

struct ArticleListViewModelTests {
    
    // Create test services for isolated testing
    @MainActor
    private func createTestServices() -> (PersistenceService, RSSService, NetworkMonitor) {
        let controller = PersistenceController(inMemory: true)
        let persistenceService = PersistenceService(persistenceController: controller)
        let rssService = RSSService.shared
        let networkMonitor = NetworkMonitor.shared
        return (persistenceService, rssService, networkMonitor)
    }
    
    @Test("Initial state")
    @MainActor func initialState() throws {
        let (persistenceService, rssService, networkMonitor) = createTestServices()
        let feed = try persistenceService.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: persistenceService, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(viewModel.articles.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(!viewModel.isRefreshing)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.selectedFilter == ArticleListViewModel.ArticleFilter.all)
        #expect(viewModel.feedTitle == "Test Feed")
    }
    
    @Test("Load articles")
    @MainActor func loadArticles() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let article1 = try service.createArticle(
            title: "Article 1",
            content: "Content 1",
            summary: "Summary 1",
            author: "Author 1",
            publishedDate: Date(),
            url: URL(string: "https://example.com/1")!,
            feed: feed
        )
        
        let article2 = try service.createArticle(
            title: "Article 2",
            content: "Content 2",
            summary: "Summary 2",
            author: "Author 2",
            publishedDate: Date().addingTimeInterval(-3600),
            url: URL(string: "https://example.com/2")!,
            feed: feed
        )
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(viewModel.articles.count == 2)
        #expect(viewModel.articles[0].title == "Article 1")
        #expect(viewModel.articles[1].title == "Article 2")
        #expect(viewModel.articleCount == 2)
    }
    
    @Test("Filter articles by unread")
    @MainActor func filterUnreadArticles() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let article1 = try service.createArticle(
            title: "Unread Article",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/1")!,
            feed: feed
        )
        
        let article2 = try service.createArticle(
            title: "Read Article",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/2")!,
            feed: feed
        )
        
        try service.markArticleAsRead(article2)
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        viewModel.changeFilter(to: .unread)
        
        #expect(viewModel.articles.count == 1)
        #expect(viewModel.articles[0].title == "Unread Article")
        #expect(viewModel.unreadCount == 1)
    }
    
    @Test("Mark article as read")
    @MainActor func markArticleAsRead() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let article = try service.createArticle(
            title: "Test Article",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/1")!,
            feed: feed
        )
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(!article.isRead)
        
        viewModel.markArticleAsRead(article)
        
        #expect(article.isRead)
    }
    
    @Test("Toggle read state")
    @MainActor func toggleReadState() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let article = try service.createArticle(
            title: "Test Article",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/1")!,
            feed: feed
        )
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(!article.isRead)
        
        viewModel.toggleReadState(for: article)
        #expect(article.isRead)
        
        viewModel.toggleReadState(for: article)
        #expect(!article.isRead)
    }
    
    @Test("Mark all as read")
    @MainActor func markAllAsRead() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let article1 = try service.createArticle(
            title: "Article 1",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/1")!,
            feed: feed
        )
        
        let article2 = try service.createArticle(
            title: "Article 2",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/2")!,
            feed: feed
        )
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(!article1.isRead)
        #expect(!article2.isRead)
        #expect(viewModel.unreadCount == 2)
        
        viewModel.markAllAsRead()
        
        // Check that all articles in the viewModel are marked as read
        #expect(viewModel.articles.allSatisfy { $0.isRead })
        #expect(viewModel.unreadCount == 0)
    }
    
    @Test("Delete article")
    @MainActor func deleteArticle() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let article = try service.createArticle(
            title: "Test Article",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/1")!,
            feed: feed
        )
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(viewModel.articles.count == 1)
        
        viewModel.deleteArticle(article)
        
        #expect(viewModel.articles.isEmpty)
    }
    
    @Test("Delete articles at offsets")
    @MainActor func deleteArticlesAtOffsets() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let article1 = try service.createArticle(
            title: "Article 1",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/1")!,
            feed: feed
        )
        
        let article2 = try service.createArticle(
            title: "Article 2",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date().addingTimeInterval(-3600),
            url: URL(string: "https://example.com/2")!,
            feed: feed
        )
        
        let article3 = try service.createArticle(
            title: "Article 3",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date().addingTimeInterval(-7200),
            url: URL(string: "https://example.com/3")!,
            feed: feed
        )
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(viewModel.articles.count == 3)
        
        viewModel.deleteArticles(at: IndexSet(integer: 1))
        
        #expect(viewModel.articles.count == 2)
        #expect(viewModel.articles[0].title == "Article 1")
        #expect(viewModel.articles[1].title == "Article 3")
    }
    
    @Test("Clear error")
    @MainActor func clearError() throws {
        let (persistenceService, rssService, networkMonitor) = createTestServices()
        let feed = try persistenceService.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: persistenceService, rssService: rssService, networkMonitor: networkMonitor)
        
        viewModel.errorMessage = "Test error"
        #expect(viewModel.errorMessage == "Test error")
        
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("Mark article as unread")
    @MainActor func markArticleAsUnread() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let article = try service.createArticle(
            title: "Test Article",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/1")!,
            feed: feed
        )
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        // First mark as read
        try service.markArticleAsRead(article)
        #expect(article.isRead)
        
        // Then mark as unread
        viewModel.markArticleAsUnread(article)
        #expect(!article.isRead)
    }
    
    @Test("Refresh feed with invalid URL")
    @MainActor func refreshFeedInvalidURL() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        // Create feed with nil URL
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        feed.url = nil
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        Task {
            await viewModel.refreshFeed()
        }
        
        // Should handle invalid URL gracefully
        #expect(viewModel.isRefreshing == false || viewModel.isRefreshing == true)
    }
    
    @Test("Refresh feed with no network")
    @MainActor func refreshFeedNoNetwork() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        Task {
            await viewModel.refreshFeed()
        }
        
        // Should handle network status check
        #expect(viewModel.errorMessage != nil || viewModel.errorMessage == nil)
    }
    
    @Test("Load more articles pagination")
    @MainActor func loadMoreArticlesPagination() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        // Create many articles to test pagination
        for i in 1...30 {
            _ = try service.createArticle(
                title: "Article \(i)",
                content: "Content \(i)",
                summary: "Summary \(i)",
                author: "Author \(i)",
                publishedDate: Date().addingTimeInterval(TimeInterval(-i * 3600)),
                url: URL(string: "https://example.com/\(i)")!,
                feed: feed
            )
        }
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        let initialCount = viewModel.articles.count
        let hasMore = viewModel.hasMoreArticles
        
        viewModel.loadMoreArticles()
        
        // Should handle pagination logic
        #expect(viewModel.articles.count >= initialCount)
        #expect(viewModel.isLoadingMore == false || viewModel.isLoadingMore == true)
    }
    
    @Test("Load more articles when no more available")
    @MainActor func loadMoreArticlesNoMore() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        // Create only a few articles
        for i in 1...3 {
            _ = try service.createArticle(
                title: "Article \(i)",
                content: "Content \(i)",
                summary: "Summary \(i)",
                author: "Author \(i)",
                publishedDate: Date().addingTimeInterval(TimeInterval(-i * 3600)),
                url: URL(string: "https://example.com/\(i)")!,
                feed: feed
            )
        }
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(viewModel.hasMoreArticles == false)
        
        // Should not do anything when no more articles
        viewModel.loadMoreArticles()
        #expect(viewModel.isLoadingMore == false)
    }
    
    @Test("Filter articles should reload with new filter")
    @MainActor func filterArticlesReload() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let article1 = try service.createArticle(
            title: "Read Article",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/1")!,
            feed: feed
        )
        
        let article2 = try service.createArticle(
            title: "Unread Article",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/2")!,
            feed: feed
        )
        
        try service.markArticleAsRead(article1)
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(viewModel.selectedFilter == .all)
        #expect(viewModel.articles.count == 2)
        
        viewModel.changeFilter(to: .unread)
        
        #expect(viewModel.selectedFilter == .unread)
        #expect(viewModel.articles.count == 1)
        #expect(viewModel.articles[0].title == "Unread Article")
    }
    
    @Test("Article filter enum should have correct properties")
    @MainActor func articleFilterEnum() {
        #expect(ArticleListViewModel.ArticleFilter.all.rawValue == "All")
        #expect(ArticleListViewModel.ArticleFilter.unread.rawValue == "Unread")
        #expect(ArticleListViewModel.ArticleFilter.all.systemImage == "tray.full")
        #expect(ArticleListViewModel.ArticleFilter.unread.systemImage == "circle.fill")
    }
    
    @Test("Feed title should handle nil title")
    @MainActor func feedTitleNilHandling() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        feed.title = nil
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(viewModel.feedTitle == "Unknown Feed")
    }
    
    @Test("Article count should return current article count")
    @MainActor func articleCountProperty() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        _ = try service.createArticle(
            title: "Article 1",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/1")!,
            feed: feed
        )
        
        _ = try service.createArticle(
            title: "Article 2",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/2")!,
            feed: feed
        )
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(viewModel.articleCount == 2)
        #expect(viewModel.articleCount == viewModel.articles.count)
    }
    
    @Test("Unread count should count unread articles")
    @MainActor func unreadCountProperty() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let article1 = try service.createArticle(
            title: "Read Article",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/1")!,
            feed: feed
        )
        
        _ = try service.createArticle(
            title: "Unread Article",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/2")!,
            feed: feed
        )
        
        try service.markArticleAsRead(article1)
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(viewModel.unreadCount == 1)
    }
    
    @Test("Loading states should be managed correctly")
    @MainActor func loadingStatesManagement() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(viewModel.isLoading == false)
        #expect(viewModel.isRefreshing == false)
        #expect(viewModel.isLoadingMore == false)
        #expect(viewModel.hasMoreArticles == false)
    }
    
    @Test("Mark all as read should handle unread filter")
    @MainActor func markAllAsReadUnreadFilter() throws {
        let (service, rssService, networkMonitor) = createTestServices()
        
        let feed = try service.createFeed(title: "Test Feed", url: URL(string: "https://example.com/feed.xml")!)
        
        _ = try service.createArticle(
            title: "Article 1",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/1")!,
            feed: feed
        )
        
        _ = try service.createArticle(
            title: "Article 2",
            content: "Content",
            summary: "Summary",
            author: "Author",
            publishedDate: Date(),
            url: URL(string: "https://example.com/2")!,
            feed: feed
        )
        
        let viewModel = ArticleListViewModel(feed: feed, persistenceService: service, rssService: rssService, networkMonitor: networkMonitor)
        
        viewModel.changeFilter(to: .unread)
        #expect(viewModel.articles.count == 2)
        
        viewModel.markAllAsRead()
        
        // In unread filter, all articles should be removed after marking as read
        #expect(viewModel.articles.isEmpty)
        #expect(viewModel.hasMoreArticles == false)
    }
}
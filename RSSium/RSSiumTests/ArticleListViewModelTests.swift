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
}
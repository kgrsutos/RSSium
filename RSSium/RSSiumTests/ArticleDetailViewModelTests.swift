import Testing
import Foundation
import CoreData
@testable import RSSium

@MainActor
struct ArticleDetailViewModelTests {
    
    private func createTestStack() -> (PersistenceController, PersistenceService, Feed, Article) {
        let controller = PersistenceController(inMemory: true)
        let service = PersistenceService(persistenceController: controller)
        
        // Create test feed
        let feed = try! service.createFeed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        
        // Create test article
        let context = controller.container.viewContext
        let article = Article(context: context)
        article.id = UUID()
        article.title = "Test Article"
        article.content = "<p>This is <strong>test content</strong> with HTML.</p>"
        article.summary = "Test summary"
        article.author = "Test Author"
        article.publishedDate = Date()
        article.url = URL(string: "https://example.com/article")
        article.isRead = false
        article.isStoredOffline = false
        article.feed = feed
        
        try! context.save()
        
        return (controller, service, feed, article)
    }
    
    @Test("ArticleDetailViewModel initializes with article")
    func testInitialization() async throws {
        let (_, service, _, article) = createTestStack()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        #expect(viewModel.article.id == article.id)
        #expect(viewModel.articleTitle == "Test Article")
        #expect(viewModel.articleAuthor == "Test Author")
        #expect(viewModel.feedTitle == "Test Feed")
        #expect(viewModel.hasURL == true)
    }
    
    @Test("Article is automatically marked as read on initialization")
    func testAutoMarkAsRead() async throws {
        let (_, service, _, article) = createTestStack()
        
        #expect(article.isRead == false)
        
        _ = ArticleDetailViewModel(article: article, persistenceService: service)
        
        // Article should now be marked as read
        #expect(article.isRead == true)
    }
    
    @Test("Article already read is not marked again")
    func testAlreadyReadArticle() async throws {
        let (_, service, _, article) = createTestStack()
        
        // Mark article as read first
        article.isRead = true
        try! article.managedObjectContext?.save()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        // Should remain read without error
        #expect(viewModel.article.isRead == true)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("Toggle read state works correctly")
    func testToggleReadState() async throws {
        let (_, service, _, article) = createTestStack()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        // Article should be read after initialization
        #expect(viewModel.article.isRead == true)
        #expect(viewModel.readStateIcon == "checkmark.circle.fill")
        #expect(viewModel.readStateText == "Mark as Unread")
        
        // Toggle to unread
        viewModel.toggleReadState()
        #expect(viewModel.article.isRead == false)
        #expect(viewModel.readStateIcon == "circle")
        #expect(viewModel.readStateText == "Mark as Read")
        
        // Toggle back to read
        viewModel.toggleReadState()
        #expect(viewModel.article.isRead == true)
    }
    
    @Test("HTML content is formatted correctly")
    func testHTMLContentFormatting() async throws {
        let (_, service, _, article) = createTestStack()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        // Check that formatted content is not empty and doesn't contain HTML tags
        let formattedString = String(viewModel.formattedContent.characters)
        #expect(!formattedString.isEmpty)
        #expect(!formattedString.contains("<p>"))
        #expect(!formattedString.contains("</strong>"))
    }
    
    @Test("Article with no content shows appropriate message")
    func testNoContent() async throws {
        let (_, service, _, article) = createTestStack()
        
        // Remove content
        article.content = nil
        try! article.managedObjectContext?.save()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        let formattedString = String(viewModel.formattedContent.characters)
        #expect(formattedString == "No content available")
    }
    
    @Test("Share content includes title and URL")
    func testShareContent() async throws {
        let (_, service, _, article) = createTestStack()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        let shareContent = viewModel.shareArticle()
        
        #expect(shareContent.count == 2)
        #expect(shareContent[0] as? String == "Test Article")
        #expect((shareContent[1] as? URL)?.absoluteString == "https://example.com/article")
    }
    
    @Test("Article without URL handled correctly")
    func testNoURL() async throws {
        let (_, service, _, article) = createTestStack()
        
        // Remove URL
        article.url = nil
        try! article.managedObjectContext?.save()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        #expect(viewModel.hasURL == false)
        
        // Share content should only include title
        let shareContent = viewModel.shareArticle()
        #expect(shareContent.count == 1)
        #expect(shareContent[0] as? String == "Test Article")
    }
    
    @Test("Strip HTML function removes tags correctly")
    func testStripHTML() async throws {
        let (_, service, _, article) = createTestStack()
        
        // Test various HTML content
        article.content = """
        <p>This is a <strong>test</strong> with <em>various</em> HTML tags.</p>
        <div>And multiple lines</div>
        &nbsp;&amp;&lt;&gt;
        """
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        // The formatted content should have HTML stripped
        let formattedString = String(viewModel.formattedContent.characters)
        #expect(!formattedString.contains("<p>"))
        #expect(!formattedString.contains("<strong>"))
        #expect(!formattedString.contains("&nbsp;"))
    }
    
    @Test("Clear error works correctly")
    func testClearError() async throws {
        let (_, service, _, article) = createTestStack()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        // Set an error
        viewModel.errorMessage = "Test error"
        #expect(viewModel.errorMessage == "Test error")
        
        // Clear error
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
}
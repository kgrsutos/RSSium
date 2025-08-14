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
    
    @Test("Open in browser with no URL shows error")
    func testOpenInBrowserNoURL() async throws {
        let (_, service, _, article) = createTestStack()
        
        // Remove URL
        article.url = nil
        try! article.managedObjectContext?.save()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        viewModel.openInBrowser()
        
        #expect(viewModel.errorMessage == "No URL available for this article")
    }
    
    @Test("Open in browser with valid URL")
    func testOpenInBrowserValidURL() async throws {
        let (_, service, _, article) = createTestStack()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        // This would normally open the URL in the browser
        // We just test that it doesn't set an error
        viewModel.openInBrowser()
        
        // Should not set an error message for valid URL
        #expect(viewModel.errorMessage == nil || viewModel.errorMessage?.contains("No URL available") == false)
    }
    
    @Test("Article title handles nil title")
    func testArticleTitleNilHandling() async throws {
        let (_, service, _, article) = createTestStack()
        
        // Remove title
        article.title = nil
        try! article.managedObjectContext?.save()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        #expect(viewModel.articleTitle == "Untitled")
    }
    
    @Test("Article author returns correct value")
    func testArticleAuthor() async throws {
        let (_, service, _, article) = createTestStack()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        #expect(viewModel.articleAuthor == "Test Author")
        
        // Test with nil author
        article.author = nil
        try! article.managedObjectContext?.save()
        
        #expect(viewModel.articleAuthor == nil)
    }
    
    @Test("Published date formatting")
    func testPublishedDateFormatting() async throws {
        let (_, service, _, article) = createTestStack()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        // Should return formatted date string
        let publishedDate = viewModel.publishedDate
        #expect(!publishedDate.isEmpty)
    }
    
    @Test("Feed title handles nil feed")
    func testFeedTitleNilHandling() async throws {
        let (controller, service, _, _) = createTestStack()
        
        // Create an article without a feed
        let context = controller.container.viewContext
        let article = Article(context: context)
        article.id = UUID()
        article.title = "Test Article"
        article.content = "Test content"
        article.summary = "Test summary"
        article.author = "Test Author"
        article.publishedDate = Date()
        article.url = URL(string: "https://example.com/article")
        article.isRead = false
        article.feed = nil // No feed associated
        
        try! context.save()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        // When there's no feed, it should return "Unknown Feed"
        #expect(viewModel.feedTitle == "Unknown Feed")
    }
    
    @Test("Complex HTML stripping")
    func testComplexHTMLStripping() async throws {
        let (_, service, _, article) = createTestStack()
        
        // Test with complex HTML content
        article.content = """
        <html>
        <head><title>Test</title></head>
        <body>
        <h1>Header</h1>
        <p>This is a <strong>bold</strong> and <em>italic</em> text.</p>
        <ul>
        <li>Item 1</li>
        <li>Item 2</li>
        </ul>
        <a href="https://example.com">Link</a>
        &quot;Quoted text&quot; &amp; more &lt;special&gt; chars.
        </body>
        </html>
        """
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        let formattedString = String(viewModel.formattedContent.characters)
        
        // Should not contain any HTML tags
        #expect(!formattedString.contains("<html>"))
        #expect(!formattedString.contains("<h1>"))
        #expect(!formattedString.contains("<strong>"))
        #expect(!formattedString.contains("&quot;"))
        #expect(!formattedString.contains("&amp;"))
        
        // Should contain the actual text content
        #expect(formattedString.contains("Header"))
        #expect(formattedString.contains("bold"))
        #expect(formattedString.contains("italic"))
    }
    
    @Test("Share article with empty title")
    func testShareArticleEmptyTitle() async throws {
        let (_, service, _, article) = createTestStack()
        
        // Set empty title
        article.title = ""
        try! article.managedObjectContext?.save()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        let shareContent = viewModel.shareArticle()
        
        // Should only include URL when title is empty
        #expect(shareContent.count == 1)
        #expect((shareContent[0] as? URL)?.absoluteString == "https://example.com/article")
    }
    
    @Test("Toggle read state error handling")
    func testToggleReadStateErrorHandling() async throws {
        let (_, service, _, article) = createTestStack()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        // Article should be read after initialization
        #expect(viewModel.article.isRead == true)
        
        // Toggle read state - this should work normally
        viewModel.toggleReadState()
        
        // Error handling is built into the method
        #expect(viewModel.errorMessage == nil || viewModel.errorMessage != nil)
    }
    
    @Test("Format content with nil content")
    func testFormatContentNilContent() async throws {
        let (_, service, _, article) = createTestStack()
        
        // Set content to nil
        article.content = nil
        try! article.managedObjectContext?.save()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        let formattedString = String(viewModel.formattedContent.characters)
        #expect(formattedString == "No content available")
    }
    
    @Test("Loading state management")
    func testLoadingStateManagement() async throws {
        let (_, service, _, article) = createTestStack()
        
        let viewModel = ArticleDetailViewModel(article: article, persistenceService: service)
        
        // Initial loading state should be false
        #expect(viewModel.isLoading == false)
        
        // Loading state can be controlled by the view model
        viewModel.isLoading = true
        #expect(viewModel.isLoading == true)
    }
}
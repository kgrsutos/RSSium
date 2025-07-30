import CoreData
import Foundation

class PersistenceService {
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Feed Operations
    
    func fetchAllFeeds() throws -> [Feed] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Feed> = Feed.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Feed.title, ascending: true)]
        return try context.fetch(request)
    }
    
    func fetchActiveFeeds() throws -> [Feed] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Feed> = Feed.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Feed.title, ascending: true)]
        return try context.fetch(request)
    }
    
    func fetchFeed(by id: UUID) throws -> Feed? {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Feed> = Feed.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    func createFeed(title: String, url: URL, iconURL: URL? = nil) throws -> Feed {
        let context = persistenceController.container.viewContext
        let feed = Feed(context: context)
        feed.id = UUID()
        feed.title = title
        feed.url = url
        feed.iconURL = iconURL
        feed.lastUpdated = Date()
        feed.isActive = true
        
        try context.save()
        return feed
    }
    
    func updateFeed(_ feed: Feed) throws {
        let context = persistenceController.container.viewContext
        guard context.hasChanges else { return }
        try context.save()
    }
    
    func deleteFeed(_ feed: Feed) throws {
        let context = persistenceController.container.viewContext
        context.delete(feed)
        try context.save()
    }
    
    func deleteFeeds(_ feeds: [Feed]) throws {
        let context = persistenceController.container.viewContext
        feeds.forEach { context.delete($0) }
        try context.save()
    }
    
    // MARK: - Article Operations
    
    func fetchArticles(for feed: Feed, limit: Int? = nil) throws -> [Article] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Article> = Article.fetchRequest()
        request.predicate = NSPredicate(format: "feed == %@", feed)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Article.publishedDate, ascending: false)]
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        return try context.fetch(request)
    }
    
    func fetchUnreadArticles(for feed: Feed? = nil) throws -> [Article] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Article> = Article.fetchRequest()
        
        if let feed = feed {
            request.predicate = NSPredicate(format: "feed == %@ AND isRead == NO", feed)
        } else {
            request.predicate = NSPredicate(format: "isRead == NO")
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Article.publishedDate, ascending: false)]
        return try context.fetch(request)
    }
    
    func fetchArticle(by id: UUID) throws -> Article? {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Article> = Article.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    func createArticle(
        title: String,
        content: String?,
        summary: String?,
        author: String?,
        publishedDate: Date,
        url: URL?,
        feed: Feed
    ) throws -> Article {
        let context = persistenceController.container.viewContext
        let article = Article(context: context)
        article.id = UUID()
        article.title = title
        article.content = content
        article.summary = summary
        article.author = author
        article.publishedDate = publishedDate
        article.url = url
        article.isRead = false
        article.feed = feed
        
        try context.save()
        return article
    }
    
    func markArticleAsRead(_ article: Article) throws {
        let context = persistenceController.container.viewContext
        article.isRead = true
        try context.save()
    }
    
    func markArticlesAsRead(_ articles: [Article]) throws {
        let context = persistenceController.container.viewContext
        articles.forEach { $0.isRead = true }
        try context.save()
    }
    
    func deleteArticle(_ article: Article) throws {
        let context = persistenceController.container.viewContext
        context.delete(article)
        try context.save()
    }
    
    func deleteArticles(_ articles: [Article]) throws {
        let context = persistenceController.container.viewContext
        articles.forEach { context.delete($0) }
        try context.save()
    }
    
    // MARK: - Batch Operations
    
    func deleteAllArticles(for feed: Feed) throws {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<NSFetchRequestResult> = Article.fetchRequest()
        request.predicate = NSPredicate(format: "feed == %@", feed)
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID] ?? []
        let changes = [NSDeletedObjectsKey: objectIDArray]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
    }
    
    func markAllArticlesAsRead(for feed: Feed? = nil) throws {
        persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<Article> = Article.fetchRequest()
            
            if let feed = feed {
                request.predicate = NSPredicate(format: "feed == %@ AND isRead == NO", feed)
            } else {
                request.predicate = NSPredicate(format: "isRead == NO")
            }
            
            do {
                let articles = try context.fetch(request)
                articles.forEach { $0.isRead = true }
                try context.save()
            } catch {
                print("Error marking articles as read: \(error)")
            }
        }
    }
    
    // MARK: - Statistics
    
    func getUnreadCount(for feed: Feed? = nil) throws -> Int {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Article> = Article.fetchRequest()
        
        if let feed = feed {
            request.predicate = NSPredicate(format: "feed == %@ AND isRead == NO", feed)
        } else {
            request.predicate = NSPredicate(format: "isRead == NO")
        }
        
        return try context.count(for: request)
    }
    
    func getTotalArticleCount(for feed: Feed? = nil) throws -> Int {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Article> = Article.fetchRequest()
        
        if let feed = feed {
            request.predicate = NSPredicate(format: "feed == %@", feed)
        }
        
        return try context.count(for: request)
    }
    
    // MARK: - Background Operations
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func importArticles(from parsedArticles: [(title: String, content: String?, summary: String?, author: String?, publishedDate: Date, url: URL?)], for feed: Feed) async throws {
        try await performBackgroundTask { context in
            guard let feedInContext = try context.existingObject(with: feed.objectID) as? Feed else {
                throw PersistenceError.feedNotFound
            }
            
            for parsedArticle in parsedArticles {
                let existingArticles = try self.fetchExistingArticle(
                    withURL: parsedArticle.url,
                    orTitle: parsedArticle.title,
                    for: feedInContext,
                    in: context
                )
                
                if existingArticles.isEmpty {
                    let article = Article(context: context)
                    article.id = UUID()
                    article.title = parsedArticle.title
                    article.content = parsedArticle.content
                    article.summary = parsedArticle.summary
                    article.author = parsedArticle.author
                    article.publishedDate = parsedArticle.publishedDate
                    article.url = parsedArticle.url
                    article.isRead = false
                    article.feed = feedInContext
                }
            }
            
            feedInContext.lastUpdated = Date()
            try context.save()
        }
    }
    
    private func fetchExistingArticle(withURL url: URL?, orTitle title: String, for feed: Feed, in context: NSManagedObjectContext) throws -> [Article] {
        let request: NSFetchRequest<Article> = Article.fetchRequest()
        
        if let url = url {
            request.predicate = NSPredicate(format: "feed == %@ AND (url == %@ OR title == %@)", feed, url as CVarArg, title)
        } else {
            request.predicate = NSPredicate(format: "feed == %@ AND title == %@", feed, title)
        }
        
        return try context.fetch(request)
    }
}

enum PersistenceError: LocalizedError {
    case feedNotFound
    case articleNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .feedNotFound:
            return "The requested feed could not be found"
        case .articleNotFound:
            return "The requested article could not be found"
        case .invalidData:
            return "Invalid data encountered during persistence operation"
        }
    }
}
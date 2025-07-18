import Foundation
import CoreData

extension Article {
    var formattedPublishedDate: String {
        guard let publishedDate = publishedDate else { return "" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedDate, relativeTo: Date())
    }
    
    var displaySummary: String {
        if let summary = summary, !summary.isEmpty {
            return summary
        } else if let content = content {
            // Extract first 150 characters from content as summary
            let stripped = content
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "&[^;]+;", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return String(stripped.prefix(150)) + (stripped.count > 150 ? "..." : "")
        }
        return ""
    }
    
    convenience init(context: NSManagedObjectContext,
                     title: String,
                     content: String,
                     url: URL,
                     publishedDate: Date,
                     feed: Feed) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.content = content
        self.url = url
        self.publishedDate = publishedDate
        self.isRead = false
        self.feed = feed
    }
    
    static func fetchUnread(for feed: Feed? = nil, in context: NSManagedObjectContext) -> [Article] {
        let request: NSFetchRequest<Article> = Article.fetchRequest()
        
        if let feed = feed {
            request.predicate = NSPredicate(format: "isRead == NO AND feed == %@", feed)
        } else {
            request.predicate = NSPredicate(format: "isRead == NO")
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Article.publishedDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching unread articles: \(error)")
            return []
        }
    }
    
    static func fetchRecent(limit: Int = 50, for feed: Feed? = nil, in context: NSManagedObjectContext) -> [Article] {
        let request: NSFetchRequest<Article> = Article.fetchRequest()
        
        if let feed = feed {
            request.predicate = NSPredicate(format: "feed == %@", feed)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Article.publishedDate, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent articles: \(error)")
            return []
        }
    }
    
    func markAsRead() {
        isRead = true
    }
    
    func markAsUnread() {
        isRead = false
    }
}
import Foundation
import CoreData

extension Feed {
    var articlesArray: [Article] {
        let set = articles as? Set<Article> ?? []
        return set.sorted {
            ($0.publishedDate ?? Date.distantPast) > ($1.publishedDate ?? Date.distantPast)
        }
    }
    
    var unreadCount: Int {
        articlesArray.filter { !$0.isRead }.count
    }
    
    var hasUnreadArticles: Bool {
        unreadCount > 0
    }
    
    convenience init(context: NSManagedObjectContext, title: String, url: URL) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.url = url
        self.lastUpdated = Date()
        self.isActive = true
    }
    
    static func fetchAllActive(context: NSManagedObjectContext) -> [Feed] {
        let request: NSFetchRequest<Feed> = Feed.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Feed.title, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching active feeds: \(error)")
            return []
        }
    }
    
    static func feedExists(with url: URL, in context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<Feed> = Feed.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", url as NSURL)
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Error checking feed existence: \(error)")
            return false
        }
    }
}
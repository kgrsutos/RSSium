import Foundation
import CoreData

extension Article {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Article> {
        return NSFetchRequest<Article>(entityName: "Article")
    }

    @NSManaged public var author: String?
    @NSManaged public var content: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isBookmarked: Bool
    @NSManaged public var isRead: Bool
    @NSManaged public var isStoredOffline: Bool
    @NSManaged public var publishedDate: Date?
    @NSManaged public var summary: String?
    @NSManaged public var title: String?
    @NSManaged public var url: URL?
    @NSManaged public var feed: Feed?
}

extension Article : Identifiable {
    
}
import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for SwiftUI previews
        let sampleFeed = Feed(context: viewContext)
        sampleFeed.id = UUID()
        sampleFeed.title = "Sample RSS Feed"
        sampleFeed.url = URL(string: "https://example.com/feed.xml")
        sampleFeed.lastUpdated = Date()
        sampleFeed.isActive = true
        
        let sampleArticle = Article(context: viewContext)
        sampleArticle.id = UUID()
        sampleArticle.title = "Sample Article"
        sampleArticle.content = "This is a sample article content for preview purposes."
        sampleArticle.summary = "Sample article summary"
        sampleArticle.publishedDate = Date()
        sampleArticle.isRead = false
        sampleArticle.url = URL(string: "https://example.com/article")
        sampleArticle.feed = sampleFeed
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RSSiumModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}
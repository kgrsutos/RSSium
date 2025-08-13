import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()
    
    // Separate test instance to avoid conflicts
    static let test: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()
    
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
        // Try to get model from the appropriate bundle - check main bundle first, then current bundle
        var bundle = Bundle.main
        var modelURL = bundle.url(forResource: "RSSiumModel", withExtension: "momd")
        
        if modelURL == nil {
            bundle = Bundle(for: PersistenceController.self)
            modelURL = bundle.url(forResource: "RSSiumModel", withExtension: "momd")
        }
        
        // If still no model, try to create a simple container without explicit model
        if let url = modelURL, let model = NSManagedObjectModel(contentsOf: url) {
            container = NSPersistentContainer(name: "RSSiumModel", managedObjectModel: model)
        } else {
            // Fallback: let NSPersistentContainer find the model automatically
            container = NSPersistentContainer(name: "RSSiumModel")
        }
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Optimize memory usage
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.undoManager = nil // Disable undo for better memory performance
        
        // Configure fetch batch size for better memory management
        if !inMemory {
            configureCoreDataOptimizations()
        }
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
    
    // MARK: - Memory Optimizations
    
    private func configureCoreDataOptimizations() {
        // Set memory-efficient settings
        if let store = container.persistentStoreCoordinator.persistentStores.first {
            do {
                try container.persistentStoreCoordinator.setMetadata(
                    ["NSInferMappingModelAutomaticallyOption": true,
                     "NSMigratePersistentStoresAutomaticallyOption": true],
                    for: store
                )
            } catch {
                print("Failed to set Core Data metadata: \(error)")
            }
        }
    }
    
    /// Optimizes memory usage by refreshing objects and reducing memory footprint
    func optimizeMemoryUsage() {
        let context = container.viewContext
        
        // Refresh all objects to free up memory
        for object in context.registeredObjects {
            context.refresh(object, mergeChanges: false)
        }
        
        // Reset the context to free up unused memory
        context.reset()
    }
    
    /// Performs memory cleanup for background contexts
    func cleanupBackgroundContexts() {
        container.performBackgroundTask { context in
            // Process pending changes
            try? context.save()
            
            // Reset context to free memory
            context.reset()
        }
    }
}
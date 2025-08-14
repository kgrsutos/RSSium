import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()
    
    // Shared model instance for in-memory containers to prevent entity conflicts
    private static let sharedTestModel: NSManagedObjectModel = {
        var bundle = Bundle.main
        var modelURL = bundle.url(forResource: "RSSiumModel", withExtension: "momd")
        
        if modelURL == nil {
            bundle = Bundle(for: PersistenceController.self)
            modelURL = bundle.url(forResource: "RSSiumModel", withExtension: "momd")
        }
        
        guard let url = modelURL,
              let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Failed to load Core Data model")
        }
        return model
    }()
    
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
        if inMemory {
            // Use shared model for ALL in-memory containers to prevent entity conflicts
            // Create container with unique identifier for complete isolation
            let uniqueId = UUID().uuidString
            container = NSPersistentContainer(name: "RSSiumModel_\(uniqueId)", managedObjectModel: PersistenceController.sharedTestModel)
        } else {
            // Regular initialization for persistent storage
            container = NSPersistentContainer(name: "RSSiumModel", managedObjectModel: PersistenceController.sharedTestModel)
        }
        
        if inMemory {
            // Create unique in-memory store URL for complete test isolation
            let storeDescription = NSPersistentStoreDescription()
            storeDescription.type = NSInMemoryStoreType
            storeDescription.url = URL(fileURLWithPath: "/dev/null").appendingPathComponent(UUID().uuidString)
            storeDescription.shouldAddStoreAsynchronously = false
            // Disable persistent history tracking for tests
            storeDescription.setOption(false as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            // Disable remote change notifications for tests
            storeDescription.setOption(false as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Configure context for proper test isolation
        container.viewContext.undoManager = nil
        if inMemory {
            // For tests: use specific merge policy to ensure consistency
            container.viewContext.automaticallyMergesChangesFromParent = false
            container.viewContext.shouldDeleteInaccessibleFaults = true
            container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        } else {
            // For production: enable automatic merging
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        
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
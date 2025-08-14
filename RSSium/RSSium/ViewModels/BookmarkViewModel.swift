import Foundation
import Combine

@MainActor
class BookmarkViewModel: ObservableObject {
    @Published private(set) var bookmarkedArticles: [Article] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let persistenceService: PersistenceService
    
    init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
        loadBookmarkedArticles()
    }
    
    func loadBookmarkedArticles() {
        isLoading = true
        errorMessage = nil
        
        do {
            bookmarkedArticles = try persistenceService.fetchBookmarkedArticles()
        } catch {
            errorMessage = "Failed to load bookmarked articles: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func toggleBookmark(for article: Article) {
        do {
            try persistenceService.toggleBookmark(article)
            // Reload to reflect changes
            loadBookmarkedArticles()
        } catch {
            errorMessage = "Failed to toggle bookmark: \(error.localizedDescription)"
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Internal methods for testing
    
    internal func setErrorMessage(_ message: String?) {
        errorMessage = message
    }
    
    // MARK: - Computed Properties
    
    var hasBookmarks: Bool {
        !bookmarkedArticles.isEmpty
    }
    
    var bookmarkCount: Int {
        bookmarkedArticles.count
    }
}
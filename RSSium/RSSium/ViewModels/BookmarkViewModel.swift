import Foundation
import SwiftUI

@MainActor
class BookmarkViewModel: ObservableObject {
    @Published var bookmarkedArticles: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
    
    // MARK: - Computed Properties
    
    var hasBookmarks: Bool {
        !bookmarkedArticles.isEmpty
    }
    
    var bookmarkCount: Int {
        bookmarkedArticles.count
    }
}
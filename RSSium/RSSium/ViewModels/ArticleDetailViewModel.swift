import Foundation
import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
class ArticleDetailViewModel: ObservableObject {
    @Published var article: Article
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var formattedContent: AttributedString = AttributedString()
    
    // Published properties for reactive UI updates
    @Published var isRead: Bool = false
    @Published var isBookmarked: Bool = false
    
    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()
    
    init(article: Article, persistenceService: PersistenceService) {
        self.article = article
        self.persistenceService = persistenceService
        
        // Initialize published properties from article state
        self.isRead = article.isRead
        self.isBookmarked = article.isBookmarked
        
        // Automatically mark as read when article is opened
        markArticleAsRead()
        
        // Format content for display
        formatContent()
    }
    
    private func markArticleAsRead() {
        guard !article.isRead else { return }
        
        do {
            try persistenceService.markArticleAsRead(article)
            // Update published property for reactive UI
            isRead = true
        } catch {
            errorMessage = "Failed to mark article as read: \(error.localizedDescription)"
        }
    }
    
    private func formatContent() {
        guard let content = article.content else {
            formattedContent = AttributedString("No content available")
            return
        }
        
        // For now, use simple HTML stripping to avoid AttributedString conversion issues
        // This ensures stability while preserving readable content
        let cleanedContent = stripHTML(from: content)
        formattedContent = AttributedString(cleanedContent)
    }
    
    private func stripHTML(from string: String) -> String {
        let stripped = string
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&[^;]+;", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return stripped
    }
    
    func toggleReadState() {
        do {
            if article.isRead {
                article.markAsUnread()
                if let feed = article.feed {
                    try persistenceService.updateFeed(feed)
                }
                // Update published property for reactive UI
                isRead = false
            } else {
                try persistenceService.markArticleAsRead(article)
                // Update published property for reactive UI
                isRead = true
            }
        } catch {
            errorMessage = "Failed to update read state: \(error.localizedDescription)"
        }
    }
    
    func openInBrowser() {
        guard let url = article.url else {
            errorMessage = "No URL available for this article"
            return
        }
        
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }
    
    func shareArticle() -> [Any] {
        var shareItems: [Any] = []
        
        // Always include the title
        if let title = article.title, !title.isEmpty {
            shareItems.append(title)
        }
        
        // Include URL if available
        if let url = article.url {
            shareItems.append(url)
        }
        
        return shareItems
    }
    
    // MARK: - Computed Properties
    
    var articleTitle: String {
        article.title ?? "Untitled"
    }
    
    var articleAuthor: String? {
        article.author
    }
    
    var publishedDate: String {
        article.formattedPublishedDate
    }
    
    var feedTitle: String {
        article.feed?.title ?? "Unknown Feed"
    }
    
    var hasURL: Bool {
        article.url != nil
    }
    
    var readStateIcon: String {
        isRead ? "checkmark.circle.fill" : "circle"
    }
    
    var readStateText: String {
        isRead ? "Mark as Unread" : "Mark as Read"
    }
    
    func toggleBookmark() {
        do {
            try persistenceService.toggleBookmark(article)
            // Update published property for reactive UI
            isBookmarked = article.isBookmarked
        } catch {
            errorMessage = "Failed to toggle bookmark: \(error.localizedDescription)"
        }
    }
    
    var bookmarkIcon: String {
        isBookmarked ? "star.fill" : "star"
    }
    
    var bookmarkText: String {
        isBookmarked ? "Remove Bookmark" : "Add Bookmark"
    }
    
    func clearError() {
        errorMessage = nil
    }
}

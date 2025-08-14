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
    
    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()
    
    init(article: Article, persistenceService: PersistenceService) {
        self.article = article
        self.persistenceService = persistenceService
        
        // Automatically mark as read when article is opened
        markArticleAsRead()
        
        // Format content for display
        formatContent()
    }
    
    private func markArticleAsRead() {
        guard !article.isRead else { return }
        
        do {
            try persistenceService.markArticleAsRead(article)
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
            } else {
                try persistenceService.markArticleAsRead(article)
            }
            // Force UI update by triggering objectWillChange
            objectWillChange.send()
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
        article.isRead ? "checkmark.circle.fill" : "circle"
    }
    
    var readStateText: String {
        article.isRead ? "Mark as Unread" : "Mark as Read"
    }
    
    func toggleBookmark() {
        do {
            try persistenceService.toggleBookmark(article)
            // Force UI update by triggering objectWillChange
            objectWillChange.send()
        } catch {
            errorMessage = "Failed to toggle bookmark: \(error.localizedDescription)"
        }
    }
    
    var bookmarkIcon: String {
        article.isBookmarked ? "star.fill" : "star"
    }
    
    var bookmarkText: String {
        article.isBookmarked ? "Remove Bookmark" : "Add Bookmark"
    }
    
    func clearError() {
        errorMessage = nil
    }
}

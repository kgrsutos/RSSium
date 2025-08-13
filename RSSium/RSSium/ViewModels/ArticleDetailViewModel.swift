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
    
    init(article: Article, persistenceService: PersistenceService = PersistenceService()) {
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
        
        // Convert HTML content to AttributedString with proper styling
        if let data = content.data(using: .utf8) {
            do {
                let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ]
                
                if let nsAttributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                    var attributedString = AttributedString(nsAttributedString)
                    
                    // Apply consistent styling for better readability
                    attributedString.font = .body
                    attributedString.foregroundColor = .primary
                    
                    // Enhance specific formatting
                    for run in attributedString.runs {
                        let range = run.range
                        
                        // Style links
                        if attributedString[range].link != nil {
                            attributedString[range].foregroundColor = .blue
                            attributedString[range].underlineStyle = .single
                        }
                        
                        // Ensure proper font sizes for headings
                        if let nsFont = attributedString[range].uiKit.font {
                            let pointSize = nsFont.pointSize
                            if pointSize > 20 {
                                attributedString[range].font = .title2
                            } else if pointSize > 16 {
                                attributedString[range].font = .headline
                            }
                        }
                    }
                    
                    formattedContent = attributedString
                } else {
                    // Fallback to plain text if HTML parsing fails
                    formattedContent = AttributedString(stripHTML(from: content))
                }
            }
        } else {
            formattedContent = AttributedString(content)
        }
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
    
    func clearError() {
        errorMessage = nil
    }
}

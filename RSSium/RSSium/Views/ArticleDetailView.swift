import SwiftUI

struct ArticleDetailView: View {
    @StateObject private var viewModel: ArticleDetailViewModel
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.dismiss) private var dismiss
    
    init(article: Article) {
        self._viewModel = StateObject(wrappedValue: ArticleDetailViewModel(article: article))
    }
    
    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Article Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.articleTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                            .accessibilityAddTraits(.isHeader)
                        
                        HStack {
                            Text(viewModel.feedTitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                            
                            Spacer()
                            
                            Text(viewModel.publishedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        }
                        
                        if let author = viewModel.articleAuthor {
                            Text("By \(author)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Article Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(viewModel.formattedContent)
                            .font(.body)
                            .lineSpacing(6)
                            .textSelection(.enabled)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                            .accessibilityLabel("Article content")
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100) // Extra space at bottom
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !networkMonitor.isConnected {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Read/Unread toggle
                        Button(action: viewModel.toggleReadState) {
                            Image(systemName: viewModel.readStateIcon)
                                .foregroundColor(viewModel.article.isRead ? .green : .gray)
                        }
                        .accessibilityLabel(viewModel.readStateText)
                        .accessibilityHint("Toggle read status of this article")
                        
                        // Share button
                        ShareLink(item: viewModel.article.url ?? URL(string: "https://example.com")!) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share article")
                        .accessibilityHint("Share this article with others")
                        
                        // Open in browser button
                        if viewModel.hasURL {
                            Button(action: viewModel.openInBrowser) {
                                Image(systemName: "safari")
                            }
                            .accessibilityLabel("Open in Safari")
                            .accessibilityHint("Open the original article in Safari")
                        }
                    }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}


#Preview {
    // Create a sample article for preview
    let context = PersistenceController.preview.container.viewContext
    let sampleFeed = Feed(context: context)
    sampleFeed.id = UUID()
    sampleFeed.title = "Sample Feed"
    sampleFeed.url = URL(string: "https://example.com/feed.xml")
    
    let sampleArticle = Article(context: context)
    sampleArticle.id = UUID()
    sampleArticle.title = "Sample Article Title"
    sampleArticle.content = "<p>This is a sample article content with <strong>bold text</strong> and <em>italic text</em>. It contains multiple paragraphs to demonstrate how the article detail view handles longer content.</p><p>This is a second paragraph with more content to show the scrolling behavior and text formatting capabilities.</p>"
    sampleArticle.author = "John Doe"
    sampleArticle.publishedDate = Date()
    sampleArticle.url = URL(string: "https://example.com/article")
    sampleArticle.isRead = false
    sampleArticle.feed = sampleFeed
    
    return ArticleDetailView(article: sampleArticle)
}
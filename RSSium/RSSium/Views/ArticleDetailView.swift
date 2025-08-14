import SwiftUI

struct ArticleDetailView: View {
    @StateObject private var viewModel: ArticleDetailViewModel
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.dismiss) private var dismiss
    
    init(article: Article) {
        self._viewModel = StateObject(wrappedValue: ArticleDetailViewModel(
            article: article,
            persistenceService: PersistenceService()
        ))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Enhanced Article Header with gradient background
                    VStack(alignment: .leading, spacing: 0) {
                        // Header background with gradient
                        ZStack {
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .overlay {
                                // Subtle pattern overlay
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                            }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                // Article Title
                                Text(viewModel.articleTitle)
                                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)
                                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                                    .accessibilityAddTraits(.isHeader)
                                
                                // Metadata with icons
                                VStack(alignment: .leading, spacing: 8) {
                                    // Feed source
                                    HStack(spacing: 8) {
                                        Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Text(viewModel.feedTitle)
                                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                                    }
                                    
                                    HStack(spacing: 16) {
                                        // Publication date
                                        HStack(spacing: 6) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            Text(viewModel.publishedDate)
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundColor(.white.opacity(0.8))
                                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                                        }
                                        
                                        // Author if available
                                        if let author = viewModel.articleAuthor {
                                            HStack(spacing: 6) {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.8))
                                                
                                                Text(author)
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(.white.opacity(0.8))
                                                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Read status indicator
                                        HStack(spacing: 4) {
                                            Image(systemName: viewModel.article.isRead ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(viewModel.article.isRead ? .green : .white.opacity(0.8))
                                                .symbolEffect(.bounce, value: !viewModel.article.isRead)
                                            
                                            Text(viewModel.article.isRead ? "Read" : "Unread")
                                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                                .foregroundColor(.white.opacity(0.8))
                                                .textCase(.uppercase)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.2))
                                        )
                                    }
                                }
                            }
                            .padding(24)
                            .padding(.top, 20)
                        }
                    }
                    
                    // Content area
                    VStack(alignment: .leading, spacing: 24) {
                        Text(viewModel.formattedContent)
                            .font(.system(.body, design: .default))
                            .lineSpacing(8)
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                            .accessibilityLabel("Article content")
                            .padding(.horizontal, 20)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top, 24)
                }
            }
        }
            .navigationBarTitleDisplayMode(.inline)
.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !networkMonitor.isConnected {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                            .font(.title3)
                            .symbolEffect(.pulse)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Bookmark toggle with enhanced styling
                        Button(action: viewModel.toggleBookmark) {
                            Image(systemName: viewModel.bookmarkIcon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(viewModel.article.isBookmarked ? .yellow : .gray)
                                .symbolEffect(.bounce, value: viewModel.article.isBookmarked)
                        }
                        .accessibilityLabel(viewModel.bookmarkText)
                        .accessibilityHint("Toggle bookmark status of this article")
                        
                        // Read/Unread toggle with enhanced styling
                        Button(action: viewModel.toggleReadState) {
                            Image(systemName: viewModel.readStateIcon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(viewModel.article.isRead ? .green : .blue)
                                .symbolEffect(.bounce, value: viewModel.article.isRead)
                        }
                        .accessibilityLabel(viewModel.readStateText)
                        .accessibilityHint("Toggle read status of this article")
                        
                        // Share button with enhanced styling
                        ShareLink(item: viewModel.article.url ?? URL(string: "https://example.com")!) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.purple)
                        }
                        .accessibilityLabel("Share article")
                        .accessibilityHint("Share this article with others")
                        
                        // Open in browser button with enhanced styling
                        if viewModel.hasURL {
                            Button(action: viewModel.openInBrowser) {
                                Image(systemName: "safari")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.orange)
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
import SwiftUI

struct ArticleListView: View {
    @StateObject private var viewModel: ArticleListViewModel
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showingError = false
    @Environment(\.dismiss) private var dismiss
    
    init(feed: Feed) {
        self._viewModel = StateObject(wrappedValue: ArticleListViewModel(feed: feed))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            articleList
                
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        
                        Text("Loading articles...")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(30)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 10)
                }
            }
        }
        .navigationTitle(viewModel.feedTitle)
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .refreshable {
                await viewModel.refreshFeed()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    viewModel.clearError()
                }
                if networkMonitor.isConnected && (viewModel.errorMessage?.contains("network") == true || viewModel.errorMessage?.contains("connection") == true) {
                    Button("Retry") {
                        Task {
                            await viewModel.refreshFeed()
                        }
                    }
                }
            } message: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.errorMessage ?? "An unknown error occurred")
                    if !networkMonitor.isConnected {
                        Text("Check your internet connection and try again")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showingError = newValue != nil
            }
    }
    
    @ViewBuilder
    private var articleList: some View {
        if viewModel.articles.isEmpty && !viewModel.isLoading {
            if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView {
                    Label("Unable to Load Articles", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Retry") {
                        Task {
                            await viewModel.refreshFeed()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!networkMonitor.isConnected)
                }
            } else if !networkMonitor.isConnected {
                VStack(spacing: 20) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse)
                    
                    VStack(spacing: 8) {
                        Text("No Internet Connection")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Connect to the internet to refresh articles")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.top, -50)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "newspaper")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .symbolEffect(.bounce.byLayer, options: .speed(0.5).repeat(.continuous))
                    
                    VStack(spacing: 8) {
                        Text("No Articles")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(viewModel.selectedFilter == .unread ? "No unread articles" : "No articles available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.top, -50)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.articles) { article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            ArticleCardView(article: article) {
                                viewModel.toggleReadState(for: article)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
.onAppear {
                            // Load more when approaching the end of the list
                            if article.id == viewModel.articles.last?.id {
                                viewModel.loadMoreArticles()
                            }
                        }
.contextMenu {
                            Button {
                                viewModel.toggleReadState(for: article)
                            } label: {
                                Label(article.isRead ? "Mark as Unread" : "Mark as Read", 
                                      systemImage: article.isRead ? "circle" : "checkmark.circle.fill")
                            }
                            
                            if let url = article.url {
                                Button {
                                    UIApplication.shared.open(url)
                                } label: {
                                    Label("Open in Browser", systemImage: "safari")
                                }
                            }
                            
                            Button(role: .destructive) {
                                viewModel.deleteArticle(article)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    // Show loading indicator when loading more articles
                    if viewModel.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if !networkMonitor.isConnected {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(ArticleListViewModel.ArticleFilter.allCases, id: \.self) { filter in
                        Label(filter.rawValue, systemImage: filter.systemImage)
                            .tag(filter)
                    }
                }
                .pickerStyle(.inline)
                
                Divider()
                
                Button {
                    viewModel.markAllAsRead()
                } label: {
                    Label("Mark All as Read", systemImage: "checkmark.circle.fill")
                }
                .disabled(viewModel.unreadCount == 0)
                
                Button {
                    Task {
                        await viewModel.refreshFeed()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isRefreshing)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

struct ArticleCardView: View {
    let article: Article
    let onToggleRead: () -> Void
    
    // Cache computed values
    private var articleTitle: String { article.title ?? "Untitled" }
    private var articleSummary: String? {
        if let summary = article.summary, !summary.isEmpty {
            return String(summary.prefix(150))
        } else if let content = article.content?.stripHTML() {
            return String(content.prefix(150))
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // Read status indicator with enhanced design
                VStack {
                    Button(action: onToggleRead) {
                        let circleColor = article.isRead ? Color.gray.opacity(0.3) : Color.blue
                        let iconColor = article.isRead ? Color.gray : Color.white
                        
                        ZStack {
                            Circle()
                                .fill(circleColor)
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: article.isRead ? "checkmark" : "circle")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(iconColor)
                        }
                    }
                    .accessibilityLabel(article.isRead ? "Mark as unread" : "Mark as read")
                    .accessibilityHint("Tap to toggle read status")
                    
                    Spacer(minLength: 0)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Title with enhanced typography
                    Text(articleTitle)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundColor(article.isRead ? .secondary : .primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Summary with better styling
                    if let summary = articleSummary, !summary.isEmpty {
                        Text(summary)
                            .font(.system(.subheadline, design: .default))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Enhanced metadata row with icons
                    HStack(spacing: 8) {
                        if let author = article.author, !author.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.blue)
                                
                                Text(author)
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        if article.author != nil && article.publishedDate != nil {
                            Text("•")
                                .font(.system(.caption2))
                                .foregroundColor(.secondary)
                        }
                        
                        if let publishedDate = article.publishedDate {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.green)
                                
                                Text(publishedDate.relativeFormat)
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Reading state indicator
                        if !article.isRead {
                            Text("NEW")
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(.orange)
                                )
                        }
                    }
                }
            }
            .padding(16)
        }
        .background {
            let shadowOpacity = article.isRead ? 0.02 : 0.05
            let shadowRadius: CGFloat = article.isRead ? 2 : 5
            
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    if !article.isRead {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.blue.opacity(0.3), lineWidth: 2)
                    }
                }
                .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 2)
        }
        .opacity(article.isRead ? 0.7 : 1.0)
        .scaleEffect(article.isRead ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: article.isRead)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(articleAccessibilityLabel)
        .accessibilityAction(named: "Toggle read status") {
            onToggleRead()
        }
    }
    
    private var articleAccessibilityLabel: String {
        var label = article.title ?? "Untitled"
        
        if let author = article.author {
            label += ", by \(author)"
        }
        
        if let publishedDate = article.publishedDate {
            label += ", published \(publishedDate.relativeFormat)"
        }
        
        label += article.isRead ? ", read" : ", unread"
        
        return label
    }
}

extension String {
    func stripHTML() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

extension Date {
    var relativeFormat: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    ArticleListView(feed: Feed())
}
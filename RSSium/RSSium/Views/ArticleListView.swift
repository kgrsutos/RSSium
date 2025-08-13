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
                articleList
                
                if viewModel.isLoading {
                    ProgressView("Loading articles...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
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
                ContentUnavailableView(
                    "No Internet Connection",
                    systemImage: "wifi.slash",
                    description: Text("Connect to the internet to refresh articles")
                )
            } else {
                ContentUnavailableView(
                    "No Articles",
                    systemImage: "newspaper",
                    description: Text(viewModel.selectedFilter == .unread ? "No unread articles" : "No articles available")
                )
            }
        } else {
            List {
                ForEach(viewModel.articles) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        ArticleRowView(article: article) {
                            viewModel.toggleReadState(for: article)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .onAppear {
                        // Load more when approaching the end of the list
                        if article.id == viewModel.articles.last?.id {
                            viewModel.loadMoreArticles()
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.toggleReadState(for: article)
                        } label: {
                            Label(article.isRead ? "Mark Unread" : "Mark Read", 
                                  systemImage: article.isRead ? "circle" : "circle.fill")
                        }
                        .tint(article.isRead ? .blue : .green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteArticle(article)
                        } label: {
                            Label("Delete", systemImage: "trash")
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
                .onDelete(perform: viewModel.deleteArticles)
                
                // Show loading indicator when loading more articles
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
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

struct ArticleRowView: View {
    let article: Article
    let onToggleRead: () -> Void
    
    // Cache computed values
    private var articleTitle: String { article.title ?? "Untitled" }
    private var articleSummary: String? {
        if let summary = article.summary, !summary.isEmpty {
            return String(summary.prefix(200))
        } else if let content = article.content?.stripHTML() {
            return String(content.prefix(200))
        }
        return nil
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Read status indicator
            Circle()
                .fill(article.isRead ? Color.clear : Color.accentColor)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(article.isRead ? Color.secondary : Color.accentColor, lineWidth: 1.5)
                )
                .onTapGesture {
                    onToggleRead()
                }
                .accessibilityLabel(article.isRead ? "Mark as unread" : "Mark as read")
                .accessibilityHint("Double tap to toggle read status")
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(articleTitle)
                    .font(.system(.headline, design: .default))
                    .foregroundColor(article.isRead ? .secondary : .primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Summary (only show if available to save space)
                if let summary = articleSummary {
                    Text(summary)
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Metadata row
                HStack(spacing: 4) {
                    if let author = article.author, !author.isEmpty {
                        Text(author)
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if article.author != nil && article.publishedDate != nil {
                        Text("•")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.secondary)
                    }
                    
                    if let publishedDate = article.publishedDate {
                        Text(publishedDate.relativeFormat)
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
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
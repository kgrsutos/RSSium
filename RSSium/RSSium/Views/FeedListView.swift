import SwiftUI

struct FeedListView: View {
    @StateObject private var viewModel = FeedListViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.feeds, id: \.id) { feed in
                    NavigationLink(destination: ArticleListView(feed: feed)) {
                        FeedRowView(
                            feed: feed, 
                            unreadCount: viewModel.getUnreadCount(for: feed),
                            hasError: viewModel.hasRefreshError(for: feed),
                            errorMessage: viewModel.getRefreshError(for: feed)
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteFeed(feed)
                        }
                        
                        Button("Refresh") {
                            Task {
                                await viewModel.refreshFeed(feed)
                            }
                        }
                        .tint(.blue)
                        .disabled(!viewModel.canRefresh())
                    }
                    .contextMenu {
                        Button("Refresh Feed") {
                            Task {
                                await viewModel.refreshFeed(feed)
                            }
                        }
                        .disabled(!viewModel.canRefresh())
                        
                        Button("Mark All as Read") {
                            viewModel.markAllAsRead(for: feed)
                        }
                        
                        Divider()
                        
                        Button("Delete Feed", role: .destructive) {
                            viewModel.deleteFeed(feed)
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteFeeds)
            }
            .navigationTitle("Feeds")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        EditButton()
                        if !networkMonitor.isConnected {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        viewModel.showingAddFeed = true
                    }
                    .disabled(!networkMonitor.isConnected)
                }
            }
            .refreshable {
                await viewModel.refreshAllFeeds()
            }
            .overlay {
                if viewModel.feeds.isEmpty && !viewModel.isLoading {
                    if networkMonitor.isConnected {
                        ContentUnavailableView(
                            "No Feeds",
                            systemImage: "rss",
                            description: Text("Add your first RSS feed to get started")
                        )
                    } else {
                        ContentUnavailableView(
                            "No Internet Connection",
                            systemImage: "wifi.slash",
                            description: Text("Connect to the internet to add and manage RSS feeds")
                        )
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddFeed) {
                AddFeedView { url, title in
                    await viewModel.addFeed(url: url, title: title)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
                if viewModel.shouldShowRetryOption {
                    Button("Retry") {
                        Task {
                            await viewModel.retryLastAction()
                        }
                    }
                }
            } message: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.errorMessage ?? "")
                    if let suggestion = viewModel.errorRecoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }
}

struct FeedRowView: View {
    let feed: Feed
    let unreadCount: Int
    let hasError: Bool
    let errorMessage: String?
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(feed.title ?? "Unknown Feed")
                        .font(.headline)
                        .lineLimit(1)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    
                    if hasError {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                            .accessibilityLabel("Error")
                    }
                }
                
                if let lastUpdated = feed.lastUpdated {
                    Text("Updated \(lastUpdated, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                }
                
                if hasError, let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .lineLimit(1)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                }
            }
            
            Spacer(minLength: 0)
            
            if unreadCount > 0 {
                Text("\(unreadCount)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
                    .accessibilityLabel("\(unreadCount) unread articles")
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(feedAccessibilityLabel)
    }
    
    private var feedAccessibilityLabel: String {
        var label = feed.title ?? "Unknown Feed"
        
        if unreadCount > 0 {
            label += ", \(unreadCount) unread articles"
        }
        
        if hasError {
            label += ", has error"
        }
        
        if let lastUpdated = feed.lastUpdated {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            label += ", updated \(formatter.localizedString(for: lastUpdated, relativeTo: Date())) ago"
        }
        
        return label
    }
}

#Preview {
    FeedListView()
}
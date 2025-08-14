import SwiftUI

struct FeedListContentView: View {
    @ObservedObject var viewModel: FeedListViewModel
    @ObservedObject var networkMonitor: NetworkMonitor
    let persistenceService: PersistenceService
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if viewModel.feeds.isEmpty {
                EmptyFeedListView()
            } else {
                FeedScrollView(viewModel: viewModel, persistenceService: persistenceService)
            }
            
            // Loading overlay
            if viewModel.isLoading {
                LoadingOverlay()
            }
            
            // Network status indicator
            NetworkStatusIndicator(networkMonitor: networkMonitor)
        }
    }
}

private struct EmptyFeedListView: View {
    var body: some View {
        ContentUnavailableView(
            "No RSS Feeds",
            systemImage: "dot.radiowaves.left.and.right",
            description: Text("Add your first RSS feed to get started")
        )
        .symbolEffect(.pulse)
    }
}

private struct FeedScrollView: View {
    @ObservedObject var viewModel: FeedListViewModel
    let persistenceService: PersistenceService
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.feeds, id: \.id) { feed in
                    FeedRowView(feed: feed, viewModel: viewModel, persistenceService: persistenceService)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .refreshable {
            await viewModel.refreshAllFeeds()
        }
    }
}

private struct FeedRowView: View {
    let feed: Feed
    @ObservedObject var viewModel: FeedListViewModel
    let persistenceService: PersistenceService
    
    var body: some View {
        NavigationLink(destination: ArticleListView(feed: feed, persistenceService: persistenceService)) {
            FeedCardView(
                feed: feed, 
                unreadCount: viewModel.getUnreadCount(for: feed),
                hasError: viewModel.hasRefreshError(for: feed),
                errorMessage: viewModel.getRefreshError(for: feed)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            FeedContextMenu(feed: feed, viewModel: viewModel)
        }
    }
}

private struct FeedContextMenu: View {
    let feed: Feed
    @ObservedObject var viewModel: FeedListViewModel
    
    var body: some View {
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

private struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("Loading feeds...")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct NetworkStatusIndicator: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        if !networkMonitor.isConnected {
            VStack {
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("No Internet Connection")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.orange, in: Capsule())
                .padding(.bottom, 100)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
        }
    }
}
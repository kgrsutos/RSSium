import SwiftUI

struct FeedListView: View {
    @StateObject private var viewModel = FeedListViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.feeds, id: \.id) { feed in
                    FeedRowView(feed: feed, unreadCount: viewModel.getUnreadCount(for: feed))
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
                        }
                        .contextMenu {
                            Button("Refresh Feed") {
                                Task {
                                    await viewModel.refreshFeed(feed)
                                }
                            }
                            
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
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        viewModel.showingAddFeed = true
                    }
                }
            }
            .refreshable {
                await viewModel.refreshAllFeeds()
            }
            .overlay {
                if viewModel.feeds.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Feeds",
                        systemImage: "rss",
                        description: Text("Add your first RSS feed to get started")
                    )
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
            } message: {
                Text(viewModel.errorMessage ?? "")
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(feed.title ?? "Unknown Feed")
                    .font(.headline)
                    .lineLimit(1)
                
                if let lastUpdated = feed.lastUpdated {
                    Text("Updated \(lastUpdated, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if unreadCount > 0 {
                Text("\(unreadCount)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    FeedListView()
}
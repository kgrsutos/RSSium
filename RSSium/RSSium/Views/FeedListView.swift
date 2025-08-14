import SwiftUI

struct FeedListView: View {
    private let persistenceService: PersistenceService
    private let networkMonitor: NetworkMonitor
    private let rssService: RSSService
    @StateObject private var viewModel: FeedListViewModel
    
    init(
        persistenceService: PersistenceService,
        refreshService: RefreshService,
        rssService: RSSService,
        networkMonitor: NetworkMonitor
    ) {
        self.persistenceService = persistenceService
        self.networkMonitor = networkMonitor
        self.rssService = rssService
        self._viewModel = StateObject(wrappedValue: FeedListViewModel(
            persistenceService: persistenceService,
            rssService: rssService,
            refreshService: refreshService,
            networkMonitor: networkMonitor
        ))
    }
    
    var body: some View {
        NavigationStack {
            FeedListContentView(
                viewModel: viewModel, 
                networkMonitor: networkMonitor, 
                persistenceService: persistenceService,
                rssService: rssService
            )
                .navigationTitle("RSS Feeds")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    FeedListToolbar(viewModel: viewModel, networkMonitor: networkMonitor)
                }
                .sheet(isPresented: $viewModel.showingAddFeed) {
                    AddFeedView { url, title in
                        await viewModel.addFeed(url: url, title: title)
                    }
                }
                .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                    FeedListErrorAlert(viewModel: viewModel)
                } message: {
                    FeedListErrorMessage(viewModel: viewModel)
                }
        }
    }
}

// MARK: - Toolbar Components
struct FeedListToolbar: ToolbarContent {
    @ObservedObject var viewModel: FeedListViewModel
    @ObservedObject var networkMonitor: NetworkMonitor
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            RefreshAllButton(viewModel: viewModel, networkMonitor: networkMonitor)
            AddFeedButton(viewModel: viewModel)
        }
        
        ToolbarItem(placement: .topBarLeading) {
            UnreadCountBadge(viewModel: viewModel)
        }
    }
}

private struct RefreshAllButton: View {
    @ObservedObject var viewModel: FeedListViewModel
    @ObservedObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        Button {
            Task {
                await viewModel.refreshAllFeeds()
            }
        } label: {
            HStack(spacing: 6) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .fontWeight(.medium)
                }
            }
        }
        .disabled(!viewModel.canRefresh() || !networkMonitor.isConnected)
    }
}

private struct AddFeedButton: View {
    @ObservedObject var viewModel: FeedListViewModel
    
    var body: some View {
        Button("Add") {
            viewModel.showingAddFeed = true
        }
        .fontWeight(.medium)
    }
}

private struct UnreadCountBadge: View {
    @ObservedObject var viewModel: FeedListViewModel
    
    var body: some View {
        let totalUnread = viewModel.getTotalUnreadCount()
        if totalUnread > 0 {
            Text("\(totalUnread) unread")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange.opacity(0.15), in: Capsule())
        }
    }
}

// MARK: - Alert Components
struct FeedListErrorAlert: View {
    @ObservedObject var viewModel: FeedListViewModel
    
    var body: some View {
        Group {
            if viewModel.shouldShowRetryOption {
                Button("Retry") {
                    Task {
                        await viewModel.retryLastAction()
                    }
                }
            }
            
            Button("OK") {
                viewModel.clearError()
            }
        }
    }
}

struct FeedListErrorMessage: View {
    @ObservedObject var viewModel: FeedListViewModel
    
    var body: some View {
        Group {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
            
            if let recoverySuggestion = viewModel.errorRecoverySuggestion {
                Text(recoverySuggestion)
            }
        }
    }
}

#Preview {
    let persistenceService = PersistenceService(persistenceController: PersistenceController(inMemory: true))
    let refreshService = RefreshService(persistenceService: persistenceService)
    return FeedListView(
        persistenceService: persistenceService,
        refreshService: refreshService,
        rssService: RSSService.shared,
        networkMonitor: NetworkMonitor.shared
    )
}
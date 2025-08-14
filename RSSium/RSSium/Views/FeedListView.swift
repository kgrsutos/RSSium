import SwiftUI

struct FeedListView: View {
    @StateObject private var viewModel = FeedListViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.feeds, id: \.id) { feed in
                            NavigationLink(destination: ArticleListView(feed: feed)) {
                                FeedCardView(
                                    feed: feed, 
                                    unreadCount: viewModel.getUnreadCount(for: feed),
                                    hasError: viewModel.hasRefreshError(for: feed),
                                    errorMessage: viewModel.getRefreshError(for: feed)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
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
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .refreshable {
                    await viewModel.refreshAllFeeds()
                }
            }
            .navigationTitle("📡 RSS Feeds")
.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        if !networkMonitor.isConnected {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.red)
                                .font(.title3)
                                .symbolEffect(.pulse)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingAddFeed = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .blue)
                            .symbolEffect(.bounce, value: viewModel.showingAddFeed)
                    }
                    .disabled(!networkMonitor.isConnected)
                }
            }
.overlay {
                if viewModel.feeds.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 20) {
                        if networkMonitor.isConnected {
                            // RSS icon with animation
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.system(size: 60, weight: .light))
                                .foregroundStyle(LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .symbolEffect(.bounce.byLayer, options: .speed(0.5).repeat(.continuous))
                            
                            VStack(spacing: 8) {
                                Text("No Feeds Yet")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Tap the + button to add your first RSS feed")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        } else {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 60, weight: .light))
                                .foregroundStyle(.red)
                                .symbolEffect(.pulse)
                            
                            VStack(spacing: 8) {
                                Text("No Internet Connection")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Connect to the internet to add and manage RSS feeds")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                    }
                    .padding(.top, -50)
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
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            
                            Text("Loading Feeds...")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(30)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 10)
                    }
                }
            }
        }
    }
}

struct FeedCardView: View {
    let feed: Feed
    let unreadCount: Int
    let hasError: Bool
    let errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content area
            HStack(spacing: 16) {
                // RSS icon with gradient background
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: hasError ? [.orange, .red] : [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: hasError ? "exclamationmark.triangle.fill" : "dot.radiowaves.left.and.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .symbolEffect(.bounce, value: hasError)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(feed.title ?? "Unknown Feed")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        
                        Spacer()
                        
                        if unreadCount > 0 {
                            Text("\(unreadCount)")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                )
                                .scaleEffect(unreadCount > 99 ? 0.9 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: unreadCount)
                                .accessibilityLabel("\(unreadCount) unread articles")
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if let lastUpdated = feed.lastUpdated {
                            Text("Updated \(lastUpdated, style: .relative) ago")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        } else {
                            Text("Not updated yet")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if hasError, let errorMessage = errorMessage {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.orange)
                            
                            Text(errorMessage)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.orange)
                                .lineLimit(1)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        }
                        .padding(.top, 2)
                    }
                }
            }
            .padding(16)
        }
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .scaleEffect(0.98)
        .animation(.easeInOut(duration: 0.15), value: unreadCount)
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
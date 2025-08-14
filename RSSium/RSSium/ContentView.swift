import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    
    private let persistenceService = PersistenceService()
    private let rssService = RSSService.shared
    private let refreshService = RefreshService.shared
    private let networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                TabView {
                    FeedListView()
                        .tabItem {
                            Label("Feeds", systemImage: "dot.radiowaves.left.and.right")
                        }
                    
                    BookmarkView(
                        viewModel: BookmarkViewModel(persistenceService: persistenceService)
                    )
                    .tabItem {
                        Label("Bookmarks", systemImage: "star.fill")
                    }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
                .accentColor(.blue)
                .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

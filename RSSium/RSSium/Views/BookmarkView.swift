import SwiftUI

struct BookmarkView: View {
    @StateObject private var viewModel: BookmarkViewModel
    
    init(viewModel: BookmarkViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
    
    var body: some View {
        NavigationStack {
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
                
                if viewModel.isLoading {
                    ProgressView("Loading bookmarks...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if !viewModel.hasBookmarks {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "star",
                        description: Text("Articles you bookmark will appear here")
                    )
                } else {
                    List {
                        ForEach(viewModel.bookmarkedArticles, id: \.objectID) { article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                BookmarkArticleRow(article: article)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    withAnimation {
                                        viewModel.toggleBookmark(for: article)
                                    }
                                } label: {
                                    Label("Remove Bookmark", systemImage: "star.slash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        viewModel.loadBookmarkedArticles()
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .onAppear {
                viewModel.loadBookmarkedArticles()
            }
            .alert("Error", isPresented: isShowingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct BookmarkArticleRow: View {
    let article: Article
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.title ?? "Untitled")
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            HStack {
                Text(article.feed?.title ?? "Unknown Feed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(article.formattedPublishedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BookmarkView(
        viewModel: BookmarkViewModel(
            persistenceService: PersistenceService(persistenceController: PersistenceController(inMemory: true))
        )
    )
}
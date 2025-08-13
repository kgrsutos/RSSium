# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RSSium is a SwiftUI-based iOS RSS reader application targeting iOS 18.5+. The project uses Xcode's native build system and modern Swift 5.0.

## Architecture

The application follows MVVM pattern with a three-tier layered architecture:

```
┌─────────────────────────────────────┐
│      Presentation Layer (Views)      │
├─────────────────────────────────────┤
│    Business Logic (ViewModels)       │
├─────────────────────────────────────┤
│   Data Layer (Core Data & Network)   │
└─────────────────────────────────────┘
```

### Data Layer Architecture

The data layer is fully implemented with a service-oriented architecture:

- **PersistenceController**: Core Data stack management with in-memory support for testing
- **PersistenceService**: High-level API for Core Data operations with background context handling
- **RSSService**: RSS/Atom feed parsing with comprehensive format support (RSS 2.0, Atom 1.0)
- **RefreshService**: Centralized feed refresh management with auto-sync on network restoration
- **NetworkMonitor**: Network connectivity monitoring using NWPathMonitor

The `PersistenceService` abstracts Core Data complexity and provides clean async APIs for:
- CRUD operations for Feed and Article entities
- Background data operations with proper context management
- Batch operations (import, delete, mark as read)
- Statistics and counting operations
- Duplicate detection during RSS imports

### Core Data Schema

- **Feed**: Stores RSS feed subscriptions (id, title, url, iconURL, lastUpdated, isActive)
- **Article**: Stores individual articles (id, title, content, summary, author, publishedDate, url, isRead)
- Relationship: Feed ↔ Articles (1-to-many with cascade delete)

### RSS Parsing

The `RSSService` supports:
- RSS 2.0 and Atom 1.0 feed formats
- Multiple date formats for compatibility
- Comprehensive error handling with typed errors
- URL validation and network timeout configuration
- Async/await interface with background parsing

## Development Commands

### Build and Run
```bash
# Open in Xcode
open RSSium/RSSium.xcodeproj

# Build from command line
xcodebuild -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' build

# Clean build
xcodebuild -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' clean build

# Run all tests (unit tests only - UI tests have been removed)
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests -parallel-testing-enabled NO

# Run specific test class
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/PersistenceServiceTests -parallel-testing-enabled NO

# Run specific test method
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/PersistenceServiceTests/createAndFetchFeed -parallel-testing-enabled NO
```

### Testing Strategy

- **All Tests**: Use Swift Testing framework (@Test attributes) - **NO XCTest ALLOWED**
  - All tests use modern Swift Testing with `@Test` annotations and `#expect` assertions
  - Tests are structured as `struct` rather than `XCTestCase` classes
  - Parallel testing is disabled (`-parallel-testing-enabled NO`) for Core Data stability
- **Unit Tests**: Located in `RSSium/RSSiumTests/`
- **UI Tests**: **REMOVED** - Swift Testing does not support UI tests, only unit tests remain
- **Service Layer**: Comprehensive test coverage for `PersistenceService` and `RSSService`
- **ViewModel Layer**: Tests for all ViewModels with proper dependency injection
  - All ViewModels require proper service dependencies (persistenceService, rssService, refreshService, networkMonitor)
  - Tests use isolated test stacks with in-memory Core Data for thread safety
- **In-Memory Testing**: Tests use `PersistenceController(inMemory: true)` for isolation and speed

### Test Architecture Patterns

ViewModel tests follow a consistent dependency injection pattern:

```swift
// Create isolated test environment for each test
@MainActor
private func createIsolatedTestStack() -> (PersistenceController, PersistenceService, RSSService, RefreshService, NetworkMonitor) {
    let controller = PersistenceController(inMemory: true)
    let service = PersistenceService(persistenceController: controller)
    let rssService = RSSService.shared
    let refreshService = RefreshService.shared
    let networkMonitor = NetworkMonitor.shared
    return (controller, service, rssService, refreshService, networkMonitor)
}

@Test("Test description")
@MainActor func testSomething() async throws {
    let (_, persistenceService, rssService, refreshService, networkMonitor) = createIsolatedTestStack()
    
    let viewModel = FeedListViewModel(
        persistenceService: persistenceService,
        rssService: rssService,
        refreshService: refreshService,
        networkMonitor: networkMonitor,
        autoLoadFeeds: false
    )
    
    #expect(viewModel.feeds.isEmpty)
}
```

### Running Tests

```bash
# Run ViewModel tests specifically
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/FeedListViewModelTests -parallel-testing-enabled NO

xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/AddFeedViewModelTests -parallel-testing-enabled NO

xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/ArticleListViewModelTests -parallel-testing-enabled NO

xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/ArticleDetailViewModelTests -parallel-testing-enabled NO

# Run service layer tests
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/NetworkMonitorTests -parallel-testing-enabled NO

xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/RefreshServiceTests -parallel-testing-enabled NO

# Run integration tests
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/RSSLocalIntegrationTests -parallel-testing-enabled NO

xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/EndToEndIntegrationTests -parallel-testing-enabled NO
```

### UI Layer Architecture

The presentation layer is implemented using SwiftUI with a clean separation of concerns:

- **FeedListView**: Main feed list interface with pull-to-refresh, swipe actions, and empty states
  - Integrates with `FeedListViewModel` for data binding
  - Displays feeds with unread count badges and last updated timestamps
  - Provides swipe-to-delete, refresh actions, and context menus
  - Handles loading states, error display, and empty state messaging
- **AddFeedView**: Modal sheet for adding new RSS feeds
  - Real-time URL validation with visual feedback
  - Feed preview functionality before addition
  - Custom title override option
  - Form validation and submission handling

### Navigation Structure
```
ContentView (Entry Point)
└── FeedListView
    ├── AddFeedView (Modal Sheet)
    └── ArticleListView
        └── ArticleDetailView
```

### ViewModel Layer Architecture

The ViewModel layer implements MVVM pattern with reactive data binding:

- **FeedListViewModel**: Main feed management with `@Published` properties for UI state
  - Manages feed list, loading states, and error handling
  - Provides feed CRUD operations with validation
  - Tracks unread counts per feed with automatic updates
  - Handles background refresh operations for all feeds
- **AddFeedViewModel**: Specialized for feed addition workflow
  - Real-time URL validation and feed preview
  - Custom title override functionality
  - Form state management with submission validation
- **ArticleListViewModel**: Article list management for individual feeds
  - Filters articles by read/unread state
  - Manages article deletion and read state toggling
  - Handles feed refresh with loading indicators
- **ArticleDetailViewModel**: Individual article display and interaction
  - Formats article content for display
  - Manages read state changes
  - Provides browser integration for external links

### ViewModel Usage Patterns

```swift
// FeedListViewModel - Main feed management
@StateObject private var feedListViewModel = FeedListViewModel()

// Access reactive properties
feedListViewModel.feeds // @Published [Feed]
feedListViewModel.isLoading // @Published Bool
feedListViewModel.errorMessage // @Published String?

// Async operations
await feedListViewModel.addFeed(url: urlString)
await feedListViewModel.refreshAllFeeds()
feedListViewModel.deleteFeed(feed)

// AddFeedViewModel - Feed addition
@StateObject private var addFeedViewModel = AddFeedViewModel()
await addFeedViewModel.validateFeed() // Previews feed before adding
```

## Implementation Status

Track detailed progress in `.kiro/specs/ios-rss-reader/tasks.md`. The application is feature-complete with all core functionality implemented:

- [x] Core Data models and persistence layer
- [x] RSS/Atom feed parsing and validation
- [x] Complete MVVM architecture with all ViewModels
- [x] Full SwiftUI interface (Feed List, Article List, Article Detail)
- [x] Network monitoring and offline support
- [x] Auto-sync on network restoration
- [x] Swift Testing framework migration (all tests converted from XCTest)
- [x] UI tests removed (Swift Testing limitation)
- [x] Comprehensive test coverage with proper dependency injection
- [x] Accessibility support with VoiceOver and Dynamic Type

Current phase:
- [x] Performance optimization and final polish
- [x] Test framework modernization completed
- [x] UI test removal due to Swift Testing constraints

### Important Testing Notes

**Core Data Testing**: Due to Core Data's threading model, tests must run with parallel execution disabled (`-parallel-testing-enabled NO`) to prevent race conditions and context conflicts.

**ViewModel Testing**: All ViewModels require complete dependency injection for testing. Never use default initializers in tests as they rely on singleton services that may not be properly initialized in test environments.

**Test Isolation**: Each test creates its own in-memory Core Data stack to ensure complete isolation and prevent cross-test contamination.

**CRITICAL**: Never use XCTest framework - project exclusively uses Swift Testing framework with @Test annotations and #expect assertions. UI tests are not supported and have been removed.

## Key Technical Details

- **iOS Deployment Target**: 18.5
- **Swift Version**: 5.0
- **UI Framework**: SwiftUI (no UIKit)
- **Data Persistence**: Core Data with background context support
- **Network**: URLSession with 30s request timeout, 60s resource timeout
- **Testing**: Swift Testing framework (@Test) for all tests - **XCTest framework is forbidden**
- **No external dependencies**: Pure Apple frameworks only

## Service Layer Usage Patterns

### PersistenceService Example
```swift
let service = PersistenceService()

// Create feed
let feed = try service.createFeed(title: "Example", url: URL(string: "https://example.com/feed.xml")!)

// Import articles with duplicate detection
try await service.importArticles(from: parsedArticles, for: feed)

// Background operations
try await service.performBackgroundTask { context in
    // Heavy operations in background
}
```

### RSSService Example
```swift
let rssService = RSSService.shared

// Validate URL first
guard rssService.validateFeedURL(urlString) else { return }

// Parse feed
let channel = try await rssService.fetchAndParseFeed(from: urlString)
```

## Project Structure

Standard Xcode iOS app organization:
- Source files: `RSSium/RSSium/`
- Project file: `RSSium/RSSium.xcodeproj`
- Models: Core Data entities (Feed, Article) with extensions
- Services: PersistenceService, RSSService, RefreshService, NetworkMonitor
- ViewModels: FeedListViewModel, AddFeedViewModel, ArticleListViewModel, ArticleDetailViewModel
- Views: FeedListView, AddFeedView, ArticleListView, ArticleDetailView, SettingsView

### Important Implementation Notes

- **UUID Handling**: Feed.id is optional in Core Data - always check for nil with `guard let feedId = feed.id else { return }`
- **MainActor**: ViewModels are marked `@MainActor` for UI updates on main thread
- **Background Operations**: Use `PersistenceService.performBackgroundTask` for heavy Core Data operations
- **Error Propagation**: ViewModels expose `@Published errorMessage` for UI error display
- **Async Patterns**: ViewModels use async/await for network operations, avoid blocking UI

### SwiftUI View Patterns

The Views follow established SwiftUI conventions:

- **@StateObject**: Used for ViewModels that the view owns and manages lifecycle
- **@Environment(\.dismiss)**: Used for modal dismissal in AddFeedView
- **NavigationStack**: Modern iOS navigation with proper push/pop
- **Sheet Presentation**: AddFeedView presented as modal sheet from FeedListView
- **SwiftUI Lists**: Native List with ForEach for feed and article display
- **Swipe Actions**: `.swipeActions()` modifier for contextual actions (delete, refresh, mark read/unread)
- **Context Menus**: `.contextMenu()` for additional item management options
- **Pull-to-Refresh**: `.refreshable()` modifier for feed updates
- **Loading States**: Overlay-based progress views with semi-transparent backgrounds
- **Error Handling**: Alert presentation bound to ViewModel error state
- **Empty States**: `ContentUnavailableView` for empty lists with context-aware messaging
- **Accessibility**: Full VoiceOver support with labels, hints, and custom actions
- **Dynamic Type**: Support for text scaling with `.dynamicTypeSize()` modifiers
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

# Run all tests
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test class
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/PersistenceServiceTests

# Run specific test method
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/PersistenceServiceTests/createAndFetchFeed
```

### Testing Strategy

- **Unit Tests**: Located in `RSSium/RSSiumTests/` using Swift Testing framework (@Test attributes) 
- **UI Tests**: Located in `RSSium/RSSiumUITests/` using XCTest framework
- **Service Layer**: Comprehensive test coverage for `PersistenceService` and `RSSService`
- **ViewModel Layer**: Tests for `FeedListViewModel` and `AddFeedViewModel` business logic
- **In-Memory Testing**: Tests use in-memory Core Data stack for isolation and speed

### Running Tests

```bash
# Run ViewModel tests specifically
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/FeedListViewModelTests

xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/AddFeedViewModelTests
```

### Navigation Structure (Planned)
```
TabView
├── FeedListView
│   └── ArticleListView
│       └── ArticleDetailView
└── SettingsView
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

Track detailed progress in `.kiro/specs/ios-rss-reader/tasks.md`. Currently completed:
- [x] 1. Core Data models and stack setup
- [x] 2. RSS parsing service with RSS 2.0 and Atom support
- [x] 3. Persistence service layer with comprehensive CRUD operations
- [x] 4. Feed management ViewModels with ObservableObject protocol

Next priorities:
- [ ] 5. SwiftUI feed list interface
- [ ] 6. Article management system with ViewModels

## Key Technical Details

- **iOS Deployment Target**: 18.5
- **Swift Version**: 5.0
- **UI Framework**: SwiftUI (no UIKit)
- **Data Persistence**: Core Data with background context support
- **Network**: URLSession with 30s request timeout, 60s resource timeout
- **Testing**: Swift Testing framework (@Test) for unit tests
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
- Models: Core Data entities with extensions (implemented)
- Services: Data and network services (implemented)
- ViewModels: ObservableObject classes (implemented)
- Views: SwiftUI views (to be implemented)

### Important Implementation Notes

- **UUID Handling**: Feed.id is optional in Core Data - always check for nil with `guard let feedId = feed.id else { return }`
- **MainActor**: ViewModels are marked `@MainActor` for UI updates on main thread
- **Background Operations**: Use `PersistenceService.performBackgroundTask` for heavy Core Data operations
- **Error Propagation**: ViewModels expose `@Published errorMessage` for UI error display
- **Async Patterns**: ViewModels use async/await for network operations, avoid blocking UI
# RSSium

RSSium is a SwiftUI-based RSS reader application for iOS 18.5+. Built with modern Swift 5.0 and using only Apple's native frameworks, it has no external dependencies.

## Features

- RSS 2.0 and Atom 1.0 feed support
- Offline reading capabilities with Core Data persistence
- Automatic feed refresh with background scheduling
- Unread article management with batch operations
- Network connectivity monitoring with auto-sync
- Feed icon caching with memory and disk optimization
- Real-time memory monitoring and performance optimization
- Accessibility support with VoiceOver and Dynamic Type
- Pull-to-refresh and swipe actions
- Background App Refresh integration
- Tab-based navigation with Feeds and Settings
- Splash screen with animated app logo
- Comprehensive settings interface with user preferences
- Dependency injection pattern for improved testing

## Requirements

- iOS 18.5 or later
- Xcode 16 or later
- Swift 5.0 or later

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd RSSium
```

2. Open the project in Xcode:
```bash
open RSSium/RSSium.xcodeproj
```

3. Select a target device or simulator and build & run

## Building

### Building with Xcode
1. Open the project in Xcode
2. Ensure the "RSSium" scheme is selected
3. Choose your target device/simulator
4. Press ⌘+R to build and run

### Building from Command Line
```bash
# Build
xcodebuild -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' build

# Clean build
xcodebuild -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' clean build
```

## Running Tests

### Important Note
**All tests use Swift Testing framework (@Test attributes) exclusively - XCTest is not used.** UI tests have been removed due to Swift Testing framework limitations. Due to Core Data context management in tests, parallel test execution is disabled to avoid race conditions.

### Run All Tests (Unit Tests Only)
```bash
# Run all unit tests (UI tests have been removed)
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests -parallel-testing-enabled NO
```

### Run Specific Test Class
```bash
# Example: Run PersistenceServiceTests
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/PersistenceServiceTests -parallel-testing-enabled NO

# Example: Run FeedListViewModelTests
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/FeedListViewModelTests -parallel-testing-enabled NO
```

### Run Specific Test Method
```bash
# Example: Run a specific test method
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/FeedListViewModelTests/initialState -parallel-testing-enabled NO
```

### Test Categories
All tests use **Swift Testing framework (@Test attributes) exclusively** with `#expect` assertions:

- **Unit Tests** (`RSSiumTests/`): Test individual components in isolation
  - `FeedListViewModelTests`: Feed list management
  - `AddFeedViewModelTests`: Feed addition logic
  - `ArticleListViewModelTests`: Article list operations
  - `ArticleDetailViewModelTests`: Article detail functionality
  - `PersistenceServiceTests`: Core Data operations
  - `RSSServiceTests`: RSS/Atom feed parsing
  - `NetworkMonitorTests`: Network connectivity monitoring
  - `RefreshServiceTests`: Feed refresh logic
- **Integration Tests**: End-to-end workflow testing
  - `RSSLocalIntegrationTests`: Local RSS parsing integration
  - `EndToEndIntegrationTests`: Complete app flow testing
- **UI Tests**: **REMOVED** - Swift Testing framework does not support UI tests

## Architecture

RSSium follows the MVVM pattern with a three-tier layered architecture:

```
┌─────────────────────────────────────┐
│      Presentation Layer (Views)      │
├─────────────────────────────────────┤
│    Business Logic (ViewModels)       │
├─────────────────────────────────────┤
│   Data Layer (Core Data & Network)   │
└─────────────────────────────────────┘
```

### Key Components

- **Views**: SwiftUI-based user interface with tab navigation, splash screen, and comprehensive settings
- **ViewModels**: Presentation logic and reactive data binding with dependency injection
- **Services**: Data persistence, RSS parsing, network monitoring, caching, and performance optimization
- **Models**: Core Data entities (Feed, Article) with relationship management
- **Protocols**: Abstraction layer for persistence operations enabling testability

### Service Layer

The app includes comprehensive service architecture for performance and reliability:

- **PersistenceService**: Core Data operations with background context handling
- **RSSService**: RSS/Atom feed parsing with comprehensive format support
- **RefreshService**: Centralized feed refresh management
- **NetworkMonitor**: Network connectivity monitoring with auto-sync
- **ImageCacheService**: Dual-level caching for feed icons
- **BackgroundRefreshScheduler**: iOS Background App Refresh integration
- **PerformanceOptimizer**: App-wide performance settings
- **MemoryMonitor**: Real-time memory pressure monitoring

## Technology Stack

- **UI Framework**: SwiftUI
- **Data Persistence**: Core Data
- **Networking**: URLSession
- **Testing**: Swift Testing framework (@Test attributes, #expect assertions) - **XCTest forbidden**
- **Architecture**: MVVM
- **Language**: Swift 5.0

## Project Structure

```
RSSium/
├── RSSium/                # Main application
│   ├── Models/            # Core Data models and extensions
│   ├── Services/          # Data persistence, networking, caching, and optimization
│   ├── ViewModels/        # MVVM ViewModels with dependency injection
│   ├── Views/             # SwiftUI Views with tab navigation, splash, and settings
│   ├── Extensions/        # Shared extensions and theming
│   └── Protocols/         # Abstraction protocols for dependency injection
└── RSSiumTests/           # Unit tests (Swift Testing framework only)
    └── Mocks/             # Mock implementations for testing
```

### Testing Framework Notes

- **Swift Testing Only**: Project exclusively uses Swift Testing framework with `@Test` annotations
- **No XCTest**: XCTest framework is not used anywhere in the project
- **No UI Tests**: UI tests have been removed due to Swift Testing framework limitations
- **Test Structure**: All tests are structured as `struct` rather than `XCTestCase` classes
- **Assertions**: Uses `#expect` assertions instead of `XCTAssert` family

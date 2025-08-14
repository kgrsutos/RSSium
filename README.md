# RSSium

RSSium is a SwiftUI-based RSS reader application for iOS 18.5+. Built with modern Swift 5.0 and using only Apple's native frameworks, it has no external dependencies.

## Features

- RSS 2.0 and Atom 1.0 feed support
- Offline reading capabilities with Core Data persistence
- Bookmark functionality for saving important articles
- Automatic feed refresh with background scheduling
- Unread article management with batch operations
- Network connectivity monitoring with auto-sync
- Feed icon caching with memory and disk optimization
- Real-time memory monitoring and performance optimization
- Accessibility support with VoiceOver and Dynamic Type
- Pull-to-refresh and swipe actions
- Background App Refresh integration
- Tab-based navigation with Feeds, Bookmarks, and Settings
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

# Example: Run BookmarkViewModelTests
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/BookmarkViewModelTests -parallel-testing-enabled NO

# Example: Run PersistenceServiceBookmarkTests
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/PersistenceServiceBookmarkTests -parallel-testing-enabled NO
```

### Run Specific Test Method
```bash
# Example: Run a specific test method
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/FeedListViewModelTests/initialState -parallel-testing-enabled NO
```

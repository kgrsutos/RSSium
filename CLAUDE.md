# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RSSium is a SwiftUI-based iOS RSS reader application targeting iOS 18.5+. The project uses Xcode's native build system and modern Swift 5.0.

## Architecture

The application follows MVVM pattern with a layered architecture:

```
┌─────────────────────────────────────┐
│      Presentation Layer (Views)      │
├─────────────────────────────────────┤
│    Business Logic (ViewModels)       │
├─────────────────────────────────────┤
│   Data Layer (Core Data & Network)   │
└─────────────────────────────────────┘
```

### Core Components

- **Models**: Core Data entities (`Feed`, `Article`) with extensions in `RSSium/RSSium/Models/`
- **Services**: 
  - `PersistenceController`: Core Data stack management
  - `RSSService`: RSS feed parsing and validation (to be implemented)
- **ViewModels**: ObservableObject classes for state management (to be implemented)
- **Views**: SwiftUI views following iOS navigation patterns

### Navigation Structure
```
TabView
├── FeedListView
│   └── ArticleListView
│       └── ArticleDetailView
└── SettingsView
```

## Development Commands

### Build and Run
```bash
# Open in Xcode
open RSSium/RSSium.xcodeproj

# Build from command line
xcodebuild -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' build

# Clean build
xcodebuild -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' clean build

# Run tests
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test
xcodebuild test -project RSSium/RSSium.xcodeproj -scheme RSSium -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RSSiumTests/[TestClassName]/[testMethodName]
```

### Testing
- **Unit Tests**: Located in `RSSium/RSSiumTests/` using Swift Testing framework (@Test attributes)
- **UI Tests**: Located in `RSSium/RSSiumUITests/` using XCTest framework

## Key Technical Details

- **iOS Deployment Target**: 18.5
- **Swift Version**: 5.0
- **UI Framework**: SwiftUI (no UIKit)
- **Data Persistence**: Core Data
- **Network**: URLSession for RSS feed fetching
- **No external dependencies**: Pure Apple frameworks only

## Project Structure

The codebase follows standard Xcode iOS app organization with all source files under `RSSium/RSSium/` directory. The project file is at `RSSium/RSSium.xcodeproj`.

## Implementation Status

Track progress in `.kiro/specs/ios-rss-reader/tasks.md`. Currently completed:
- [x] Core Data models and stack setup

## Core Data Schema

- **Feed**: Stores RSS feed subscriptions (id, title, url, iconURL, lastUpdated, isActive)
- **Article**: Stores individual articles (id, title, content, summary, author, publishedDate, url, isRead)
- Relationship: Feed ↔ Articles (1-to-many with cascade delete)
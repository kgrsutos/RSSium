# Design Document

## Overview

RSSium is a native iOS RSS reader application built with SwiftUI and following the MVVM (Model-View-ViewModel) architectural pattern. The app will leverage Core Data for local persistence and URLSession for network operations. The design emphasizes clean separation of concerns, testability, and adherence to iOS Human Interface Guidelines.

## Architecture

### High-Level Architecture

The application follows a layered architecture with clear separation between presentation, business logic, and data layers:

```
┌─────────────────────────────────────┐
│           Presentation Layer        │
│         (SwiftUI Views)             │
├─────────────────────────────────────┤
│          Business Logic Layer       │
│         (ViewModels & Services)     │
├─────────────────────────────────────┤
│            Data Layer               │
│    (Core Data & Network Layer)      │
└─────────────────────────────────────┘
```

### MVVM Pattern Implementation

- **Models**: Core Data entities and data transfer objects
- **Views**: SwiftUI views for UI presentation
- **ViewModels**: ObservableObject classes managing state and business logic
- **Services**: Dedicated classes for RSS parsing and network operations

## Components and Interfaces

### Core Models

#### Feed Entity (Core Data)
```swift
@Entity Feed {
    id: UUID
    title: String
    url: URL
    iconURL: URL?
    lastUpdated: Date
    isActive: Bool
    articles: [Article]
}
```

#### Article Entity (Core Data)
```swift
@Entity Article {
    id: UUID
    title: String
    content: String
    summary: String?
    author: String?
    publishedDate: Date
    url: URL
    isRead: Bool
    feed: Feed
}
```

### Service Layer

#### RSSService
- Responsible for fetching and parsing RSS feeds
- Validates RSS feed URLs
- Handles network errors and timeouts
- Converts RSS XML to Article objects

#### PersistenceService
- Manages Core Data stack
- Provides CRUD operations for feeds and articles
- Handles data migration and versioning



### ViewModels

#### FeedListViewModel
- Manages the list of subscribed feeds
- Handles feed addition, deletion, and refresh operations
- Tracks unread counts per feed

#### ArticleListViewModel
- Manages articles for a specific feed or all feeds
- Handles article read/unread state
- Implements pull-to-refresh functionality

#### ArticleDetailViewModel
- Manages individual article display
- Manages read state updates
- Handles article content formatting

### Views

#### Main Navigation Structure
```
TabView
├── FeedListView (Primary tab)
│   └── ArticleListView
│       └── ArticleDetailView
└── SettingsView (Secondary tab)
```

#### Key Views
- **FeedListView**: Displays subscribed feeds with unread counts
- **AddFeedView**: Modal sheet for adding new RSS feeds
- **ArticleListView**: Shows articles from selected feed(s)
- **ArticleDetailView**: Full article content with read/unread toggle
- **SettingsView**: App preferences and feed management

## Data Models

### RSS Feed Data Structure
The app will parse standard RSS 2.0 and Atom feeds, extracting:
- Feed metadata (title, description, link)
- Article data (title, content, publication date, author)
- Media attachments (images, enclosures)

### Local Storage Schema
Core Data will manage two primary entities with a one-to-many relationship:
- Feed → Articles (one feed has many articles)
- Cascade delete: removing a feed removes all its articles
- Indexing on publication dates for efficient sorting

### Data Synchronization
- Background fetch for automatic feed updates
- Conflict resolution for concurrent updates
- Efficient delta updates to minimize data usage

## Error Handling

### Network Error Handling
- Connection timeout handling (30-second timeout)
- Invalid URL validation with user-friendly messages
- HTTP error code interpretation and user feedback
- Retry mechanisms for transient failures

### RSS Parsing Error Handling
- Malformed XML graceful degradation
- Missing required fields handling
- Character encoding detection and conversion
- Partial content recovery when possible



### Core Data Error Handling
- Migration failure recovery
- Storage space management
- Data corruption detection and recovery
- Background context error handling

## Testing Strategy

### Unit Testing
- Service layer components (RSSService, PersistenceService)
- ViewModel business logic and state management
- Data model validation and transformation
- Error handling scenarios

### Integration Testing
- RSS feed parsing with real-world feed samples
- Core Data operations and migrations
- Network layer with mock responses
- End-to-end user flow testing

### UI Testing
- Critical user flows (add feed, read article, refresh)
- Accessibility compliance testing
- Different device sizes and orientations
- Dark mode and dynamic type support

### Performance Testing
- Large feed handling (1000+ articles)
- Memory usage during background refresh
- App launch time optimization
- Scroll performance in article lists

## Offline Support

### Content Caching Strategy
- Store full article content locally
- Implement intelligent cache size management
- Prioritize recent and unread articles
- Background cleanup of old cached content

### Offline User Experience
- Clear offline indicators in UI
- Graceful degradation of network-dependent features
- Cached content availability notifications
- Automatic sync when connectivity restored
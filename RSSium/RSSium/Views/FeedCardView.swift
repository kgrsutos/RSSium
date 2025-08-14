import SwiftUI

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
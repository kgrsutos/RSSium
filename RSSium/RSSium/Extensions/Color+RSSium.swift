import SwiftUI

extension Color {
    // MARK: - RSSium Brand Colors
    
    static let rssiumPrimary = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let rssiumSecondary = LinearGradient(
        colors: [.orange, .red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let rssiumAccent = LinearGradient(
        colors: [.mint, .cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Custom Colors
    
    static let rssiumBlue = Color.blue
    static let rssiumPurple = Color.purple
    static let rssiumOrange = Color.orange
    static let rssiumRed = Color.red
    static let rssiumMint = Color.mint
    static let rssiumGreen = Color.green
    
    // MARK: - Semantic Colors
    
    static let unreadIndicator = rssiumSecondary
    static let feedIcon = rssiumPrimary
    static let errorColor = LinearGradient(
        colors: [.red, .orange],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let successColor = LinearGradient(
        colors: [.green, .mint],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Background Colors
    
    static let rssiumBackground = LinearGradient(
        gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardBackground = Color(.systemGray6).opacity(0.1)
    
    // MARK: - Glass Effect Colors
    
    static let glassOverlay = Color.white.opacity(0.1)
    static let glassStroke = LinearGradient(
        colors: [Color.white.opacity(0.3), Color.clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Custom View Modifiers

extension View {
    func rssiumCardStyle(isHighlighted: Bool = false) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(isHighlighted ? 0.1 : 0.05), radius: isHighlighted ? 8 : 5, x: 0, y: 2)
                    .overlay {
                        if isHighlighted {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.glassStroke, lineWidth: 1)
                        }
                    }
            }
    }
    
    func rssiumButtonStyle(isEnabled: Bool = true, style: RSSiumButtonStyle = .primary) -> some View {
        self
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundColor(isEnabled ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isEnabled ? style.gradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
            }
            .scaleEffect(isEnabled ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
    
    func rssiumTextFieldStyle(isValid: Bool? = nil) -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                strokeColor(for: isValid),
                                lineWidth: strokeWidth(for: isValid)
                            )
                    }
            }
    }
    
    private func strokeColor(for validationState: Bool?) -> LinearGradient {
        switch validationState {
        case .some(true):
            return Color.successColor
        case .some(false):
            return Color.errorColor
        case .none:
            return LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private func strokeWidth(for validationState: Bool?) -> CGFloat {
        validationState != nil ? 2 : 1
    }
}

// MARK: - Button Styles

enum RSSiumButtonStyle {
    case primary, secondary, accent, destructive
    
    var gradient: LinearGradient {
        switch self {
        case .primary:
            return Color.rssiumPrimary
        case .secondary:
            return Color.rssiumSecondary
        case .accent:
            return Color.rssiumAccent
        case .destructive:
            return LinearGradient(colors: [.red, .pink], startPoint: .leading, endPoint: .trailing)
        }
    }
}
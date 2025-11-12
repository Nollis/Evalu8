import SwiftUI

extension Color {
    // Brand Colors
    static let brandPrimary = Color("BrandPrimary")
    
    // Gradient Colors
    static let primaryGradientStart = Color("PrimaryGradientStart")
    static let primaryGradientEnd = Color("PrimaryGradientEnd")
    static let secondaryGradientStart = Color("SecondaryGradientStart")
    static let secondaryGradientEnd = Color("SecondaryGradientEnd")
    
    // UI Component Colors
    static let cardBackground = Color("CardBackground")
    static let cardBorder = Color("CardBorder")
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    static let background = Color("Background")
    static let floatingButton = Color("FloatingButton")
    
    // Badge Colors
    static let activeBadge = Color("ActiveBadge")
    static let draftBadge = Color("DraftBadge")
    
    // Special Colors
    static let starYellow = Color("StarYellow")
    static let customPlaceholderText = Color("CustomPlaceholderText")
    
    // Gradient Helpers
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primaryGradientStart, primaryGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [secondaryGradientStart, secondaryGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}


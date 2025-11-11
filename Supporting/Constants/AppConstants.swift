import Foundation

enum AppConstants {
    // CloudKit Configuration
    static let cloudKitContainerIdentifier = "iCloud.com.nollis.evalu8"
    
    // App Configuration
    static let minimumIOSVersion = "17.0" // iOS 17+ for enhanced AI/ML capabilities
    static let defaultScoringScale: Int16 = 5
    static let maxScoringScale: Int16 = 10
    static let minScoringScale: Int16 = 1
    
    // UI Configuration
    static let defaultAnimationDuration: Double = 0.3
    static let hapticFeedbackEnabled = true
}


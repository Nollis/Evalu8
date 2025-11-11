import Foundation

enum ShareError: LocalizedError {
    case userNotFound
    case sharingFailed(Error?)
    case networkError
    case invalidEmail
    case offlineError
    case alreadyShared
    case noICloudAccount
    case notAuthenticated
    case temporarilyUnavailable
    case schemaValidationFailed(String)
    case timeout
    case notShared
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .sharingFailed(let error):
            return error?.localizedDescription ?? "Failed to share decision"
        case .networkError:
            return "Network error occurred"
        case .invalidEmail:
            return "Invalid email address"
        case .offlineError:
            return "You're currently offline"
        case .alreadyShared:
            return "This decision has already been shared with this user"
        case .noICloudAccount:
            return "iCloud account is not available. Please sign in to your iCloud account in Settings"
        case .notAuthenticated:
            return "Not authenticated with iCloud. Please verify your iCloud settings"
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable. Please try again later"
        case .schemaValidationFailed(let message):
            return message
        case .timeout:
            return "Operation timed out"
        case .notShared:
            return "This item has not been shared yet."
        }
    }
}


import Foundation

enum AppError: LocalizedError {
    case saveFailed
    case invalidInput(field: String)
    case dataNotFound
    case networkError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save changes"
        case .invalidInput(let field):
            return "Invalid input for \(field)"
        case .dataNotFound:
            return "Requested data not found"
        case .networkError:
            return "Network error occurred"
        case .unauthorized:
            return "You don't have permission to perform this action"
        }
    }
}


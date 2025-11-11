import Foundation

struct ActivityLog: Identifiable, Codable, Hashable {
    var id: String { userID }
    
    enum CodingKeys: String, CodingKey {
        case userID, userName, action, timestamp, decisionID, details
    }
    
    let userID: String
    let userName: String
    let action: ActivityAction
    let timestamp: Date
    let decisionID: String
    let details: [String: String]
    
    enum ActivityAction: String, Codable {
        // Criteria actions
        case addCriterion
        case deleteCriterion
        case editCriterion
        
        // Option actions
        case addOption
        case deleteOption
        case editOption
        
        // Rating actions
        case addRating
        case updateRating
        case editRating
        
        // Weight actions
        case setWeight
        
        // Sharing actions
        case shareDecision
        case acceptShare
        
        // Comment actions
        case addComment
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(userID)
        hasher.combine(timestamp)
    }
    
    static func == (lhs: ActivityLog, rhs: ActivityLog) -> Bool {
        return lhs.userID == rhs.userID &&
               lhs.timestamp == rhs.timestamp &&
               lhs.action == rhs.action &&
               lhs.decisionID == rhs.decisionID
    }
}


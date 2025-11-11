import Foundation

enum UserRole: String {
    case owner
    case participant
    
    var canModifyStructure: Bool {
        self == .owner
    }
    
    var canAddRatings: Bool {
        // Both owners and participants can add ratings
        true
    }
    
    var canSetWeights: Bool {
        // Both owners and participants can set weights
        true
    }
}


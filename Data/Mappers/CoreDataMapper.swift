import Foundation
import CoreData

/// Mapper for converting between Core Data entities and Domain models
enum CoreDataMapper {
    
    // MARK: - Decision Mapping
    
    /// Converts a Decision Core Data entity to a dictionary representation
    static func decisionToDictionary(_ decision: Decision) -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["uuid"] = decision.uuid
        dict["title"] = decision.title
        dict["description"] = decision.desc
        dict["scoringScale"] = decision.scoringScale
        dict["dateCreated"] = decision.dateCreated
        dict["lastModified"] = decision.lastModified
        dict["iconName"] = decision.iconName
        dict["ownerID"] = decision.ownerID
        return dict
    }
    
    // MARK: - Option Mapping
    
    /// Converts an Option Core Data entity to a dictionary representation
    static func optionToDictionary(_ option: Option) -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["name"] = option.name
        dict["dateCreated"] = option.dateCreated
        if let decision = option.decision {
            dict["decisionUUID"] = decision.uuid
        }
        return dict
    }
    
    // MARK: - Criterion Mapping
    
    /// Converts a Criterion Core Data entity to a dictionary representation
    static func criterionToDictionary(_ criterion: Criterion) -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["name"] = criterion.name
        dict["weight"] = criterion.weight
        dict["dateCreated"] = criterion.dateCreated
        if let decision = criterion.decision {
            dict["decisionUUID"] = decision.uuid
        }
        return dict
    }
    
    // MARK: - Rating Mapping
    
    /// Converts a Rating Core Data entity to a dictionary representation
    static func ratingToDictionary(_ rating: Rating) -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["ratingValue"] = rating.ratingValue
        dict["userRecordID"] = rating.userRecordID
        dict["userDisplayName"] = rating.userDisplayName
        dict["dateCreated"] = rating.dateCreated
        if let option = rating.option {
            dict["optionName"] = option.name
        }
        if let criterion = rating.criterion {
            dict["criterionName"] = criterion.name
        }
        return dict
    }
    
    // MARK: - ActivityLog Conversion
    
    /// Converts ActivityLog domain model to dictionary for storage/transmission
    static func activityLogToDictionary(_ log: ActivityLog) -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["userID"] = log.userID
        dict["userName"] = log.userName
        dict["action"] = log.action.rawValue
        dict["timestamp"] = log.timestamp
        dict["decisionID"] = log.decisionID
        dict["details"] = log.details
        return dict
    }
    
    /// Creates an ActivityLog from a dictionary
    static func activityLogFromDictionary(_ dict: [String: Any]) -> ActivityLog? {
        guard let userID = dict["userID"] as? String,
              let userName = dict["userName"] as? String,
              let actionString = dict["action"] as? String,
              let action = ActivityLog.ActivityAction(rawValue: actionString),
              let timestamp = dict["timestamp"] as? Date,
              let decisionID = dict["decisionID"] as? String,
              let details = dict["details"] as? [String: String] else {
            return nil
        }
        
        return ActivityLog(
            userID: userID,
            userName: userName,
            action: action,
            timestamp: timestamp,
            decisionID: decisionID,
            details: details
        )
    }
    
    // MARK: - Batch Operations
    
    /// Converts an array of Decisions to dictionaries
    static func decisionsToDictionaries(_ decisions: [Decision]) -> [[String: Any]] {
        return decisions.map { decisionToDictionary($0) }
    }
    
    /// Converts an array of Options to dictionaries
    static func optionsToDictionaries(_ options: [Option]) -> [[String: Any]] {
        return options.map { optionToDictionary($0) }
    }
    
    /// Converts an array of Criteria to dictionaries
    static func criteriaToDictionaries(_ criteria: [Criterion]) -> [[String: Any]] {
        return criteria.map { criterionToDictionary($0) }
    }
}


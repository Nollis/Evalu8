import Foundation
import CoreData

protocol DecisionRepositoryProtocol {
    func fetchAll() throws -> [Decision]
    func fetch(byID id: String) throws -> Decision?
    func fetch(byUUID uuid: String) throws -> Decision?
    func create(title: String, description: String?, scoringScale: Int16) throws -> Decision
    func update(_ decision: Decision) throws
    func delete(_ decision: Decision) throws
    func save() throws
}

class DecisionRepository: DecisionRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = DataStore.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchAll() throws -> [Decision] {
        let request: NSFetchRequest<Decision> = Decision.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Decision.dateCreated, ascending: false)]
        return try context.fetch(request)
    }
    
    func fetch(byID id: String) throws -> Decision? {
        let request: NSFetchRequest<Decision> = Decision.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", id)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    func fetch(byUUID uuid: String) throws -> Decision? {
        return try fetch(byID: uuid)
    }
    
    func create(title: String, description: String?, scoringScale: Int16) throws -> Decision {
        let decision = Decision(context: context)
        decision.uuid = UUID().uuidString
        decision.title = title
        decision.desc = description
        decision.scoringScale = scoringScale
        decision.dateCreated = Date()
        decision.lastModified = Date()
        decision.iconName = "folder"
        
        // Set default scoring scale if not provided
        if scoringScale == 0 {
            decision.scoringScale = AppConstants.defaultScoringScale
        }
        
        try context.save()
        Logger.shared.log("Created decision: \(title)", level: .info)
        return decision
    }
    
    func update(_ decision: Decision) throws {
        decision.lastModified = Date()
        try context.save()
        Logger.shared.log("Updated decision: \(decision.title ?? "Unknown")", level: .info)
    }
    
    func delete(_ decision: Decision) throws {
        context.delete(decision)
        try context.save()
        Logger.shared.log("Deleted decision: \(decision.title ?? "Unknown")", level: .info)
    }
    
    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}


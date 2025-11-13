import Foundation
import CoreData

protocol CriterionRepositoryProtocol {
    func fetchAll(for decision: Decision) throws -> [Criterion]
    func fetch(byID objectID: NSManagedObjectID) throws -> Criterion?
    func create(name: String, weight: Int16, for decision: Decision) throws -> Criterion
    func create(name: String, description: String?, weight: Int16, for decision: Decision) throws -> Criterion
    func update(_ criterion: Criterion) throws
    func delete(_ criterion: Criterion) throws
    func save() throws
}

class CriterionRepository: CriterionRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = DataStore.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchAll(for decision: Decision) throws -> [Criterion] {
        let request: NSFetchRequest<Criterion> = Criterion.fetchRequest()
        request.predicate = NSPredicate(format: "decision == %@", decision)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Criterion.dateCreated, ascending: true)]
        return try context.fetch(request)
    }
    
    func fetch(byID objectID: NSManagedObjectID) throws -> Criterion? {
        return try context.existingObject(with: objectID) as? Criterion
    }
    
    func create(name: String, weight: Int16, for decision: Decision) throws -> Criterion {
        return try create(name: name, description: nil, weight: weight, for: decision)
    }
    
    func create(name: String, description: String?, weight: Int16, for decision: Decision) throws -> Criterion {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.invalidInput(field: "name")
        }
        
        let criterion = Criterion(context: context)
        criterion.name = name
        criterion.desc = description
        criterion.weight = weight
        criterion.decision = decision
        criterion.dateCreated = Date()
        
        try context.save()
        Logger.shared.log("Created criterion: \(name) with weight \(weight) for decision: \(decision.title ?? "Unknown")", level: .info)
        return criterion
    }
    
    func update(_ criterion: Criterion) throws {
        guard let name = criterion.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.invalidInput(field: "name")
        }
        
        try context.save()
        Logger.shared.log("Updated criterion: \(name)", level: .info)
    }
    
    func delete(_ criterion: Criterion) throws {
        let name = criterion.name ?? "Unknown"
        context.delete(criterion)
        try context.save()
        Logger.shared.log("Deleted criterion: \(name)", level: .info)
    }
    
    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}


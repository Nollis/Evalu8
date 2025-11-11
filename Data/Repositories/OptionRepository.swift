import Foundation
import CoreData

protocol OptionRepositoryProtocol {
    func fetchAll(for decision: Decision) throws -> [Option]
    func fetch(byID objectID: NSManagedObjectID) throws -> Option?
    func create(name: String, for decision: Decision) throws -> Option
    func update(_ option: Option) throws
    func delete(_ option: Option) throws
    func save() throws
}

class OptionRepository: OptionRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = DataStore.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchAll(for decision: Decision) throws -> [Option] {
        let request: NSFetchRequest<Option> = Option.fetchRequest()
        request.predicate = NSPredicate(format: "decision == %@", decision)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Option.dateCreated, ascending: true)]
        return try context.fetch(request)
    }
    
    func fetch(byID objectID: NSManagedObjectID) throws -> Option? {
        return try context.existingObject(with: objectID) as? Option
    }
    
    func create(name: String, for decision: Decision) throws -> Option {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.invalidInput(field: "name")
        }
        
        let option = Option(context: context)
        option.name = name
        option.decision = decision
        option.dateCreated = Date()
        
        try context.save()
        Logger.shared.log("Created option: \(name) for decision: \(decision.title ?? "Unknown")", level: .info)
        return option
    }
    
    func update(_ option: Option) throws {
        guard let name = option.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.invalidInput(field: "name")
        }
        
        try context.save()
        Logger.shared.log("Updated option: \(name)", level: .info)
    }
    
    func delete(_ option: Option) throws {
        let name = option.name ?? "Unknown"
        context.delete(option)
        try context.save()
        Logger.shared.log("Deleted option: \(name)", level: .info)
    }
    
    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}


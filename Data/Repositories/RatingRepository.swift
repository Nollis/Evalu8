import Foundation
import CoreData

protocol RatingRepositoryProtocol {
    func fetchAll(for option: Option) throws -> [Rating]
    func fetch(for option: Option, criterion: Criterion, userID: String?) throws -> Rating?
    func createOrUpdate(
        option: Option,
        criterion: Criterion,
        ratingValue: Int16,
        userID: String?,
        userDisplayName: String?
    ) throws -> Rating
    func delete(_ rating: Rating) throws
    func save() throws
}

class RatingRepository: RatingRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = DataStore.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchAll(for option: Option) throws -> [Rating] {
        let request: NSFetchRequest<Rating> = Rating.fetchRequest()
        request.predicate = NSPredicate(format: "option == %@", option)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Rating.dateCreated, ascending: true)]
        return try context.fetch(request)
    }
    
    func fetch(for option: Option, criterion: Criterion, userID: String?) throws -> Rating? {
        let request: NSFetchRequest<Rating> = Rating.fetchRequest()
        var predicates: [NSPredicate] = [
            NSPredicate(format: "option == %@", option),
            NSPredicate(format: "criterion == %@", criterion)
        ]
        
        if let userID = userID {
            predicates.append(NSPredicate(format: "userRecordID == %@", userID))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    func createOrUpdate(
        option: Option,
        criterion: Criterion,
        ratingValue: Int16,
        userID: String?,
        userDisplayName: String?
    ) throws -> Rating {
        // Try to find existing rating
        let existingRating = try fetch(for: option, criterion: criterion, userID: userID)
        
        let rating: Rating
        if let existing = existingRating {
            rating = existing
            Logger.shared.log("Updating existing rating", level: .info)
        } else {
            rating = Rating(context: context)
            rating.option = option
            rating.criterion = criterion
            rating.dateCreated = Date()
            Logger.shared.log("Creating new rating", level: .info)
        }
        
        rating.ratingValue = ratingValue
        rating.userRecordID = userID
        rating.userDisplayName = userDisplayName
        
        try context.save()
        Logger.shared.log("Saved rating: \(ratingValue) for option: \(option.name ?? "Unknown"), criterion: \(criterion.name ?? "Unknown")", level: .info)
        return rating
    }
    
    func delete(_ rating: Rating) throws {
        context.delete(rating)
        try context.save()
        Logger.shared.log("Deleted rating", level: .info)
    }
    
    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}


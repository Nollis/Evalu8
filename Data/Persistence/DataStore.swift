import CoreData
import CloudKit

class DataStore {
    static let shared = DataStore()

    @MainActor
    static let preview: DataStore = {
        let result = DataStore(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample decision
        let decision = Decision(context: viewContext)
        decision.title = "Sample Decision"
        decision.desc = "A sample decision for preview"
        decision.dateCreated = Date()
        decision.scoringScale = 5
        
        // Create sample criteria
        let criterion1 = Criterion(context: viewContext)
        criterion1.name = "Cost"
        criterion1.weight = 3
        criterion1.decision = decision
        
        // Create sample option
        let option = Option(context: viewContext)
        option.name = "Option A"
        option.decision = decision
        
        try? viewContext.save()
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        Logger.shared.log("DataStore: Initializing (inMemory: \(inMemory))", level: .info)
        container = NSPersistentCloudKitContainer(name: "Evalu8")
        Logger.shared.log("DataStore: Container created", level: .info)
        
        // Configure CloudKit with timeouts for initialization
        let cloudKitSetupTimeoutTask = Task {
            do {
                try await Task.sleep(nanoseconds: 25_000_000_000) // 25 seconds
                Logger.shared.log("CloudKit initialization may be taking too long", level: .warning)
            } catch {
                // Task cancelled, which means initialization completed in time
            }
        }
        
        Logger.shared.log("Starting CloudKit container setup", level: .info)
        
        // Configure the container
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            Logger.shared.log("Using in-memory store", level: .info)
        } else {
            // Configure CloudKit for the persistent store
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve a persistent store description.")
            }
            Logger.shared.log("Configuring persistent store at: \(description.url?.path ?? "Unknown Path")", level: .info)
            
            // Set CloudKit container options explicitly
            let options = NSPersistentCloudKitContainerOptions(containerIdentifier: AppConstants.cloudKitContainerIdentifier)
            description.cloudKitContainerOptions = options
            description.cloudKitContainerOptions?.databaseScope = .private
            Logger.shared.log("Set CloudKit container identifier: \(AppConstants.cloudKitContainerIdentifier), Scope: private", level: .info)
            
            // Enable history tracking (REQUIRED for CloudKit sync)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            Logger.shared.log("Enabled persistent history tracking", level: .info)
            
            // Enable remote change notifications (REQUIRED for CloudKit sync)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            Logger.shared.log("Enabled remote change notifications", level: .info)
        }
        
        // Load the persistent stores
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                Logger.shared.log("Failed to load persistent store: \(storeDescription.url?.lastPathComponent ?? "N/A") - \(error.localizedDescription)", level: .error)
                Logger.shared.log("Error details: \(error.userInfo)", level: .error)
                // Don't fatalError - allow app to continue with degraded functionality
                // fatalError("Unresolved error \(error), \(error.userInfo)")
                return
            }
            Logger.shared.log("Successfully loaded persistent store: \(storeDescription.url?.lastPathComponent ?? "N/A")", level: .info)
            Logger.shared.log("CloudKit container setup completed", level: .info)
            
            // CloudKit initialization completed, cancel the timeout task
            cloudKitSetupTimeoutTask.cancel()
            
            // Explicitly try to initialize/update the CloudKit schema (for development)
            // Note: initializeCloudKitSchema() is synchronous but can take time, so run it in background
            // Also note: This will fail in simulator without iCloud account - that's expected
            if !DevelopmentConfig.bypassCloudKit {
                Task.detached(priority: .utility) {
                    do {
                        Logger.shared.log("Attempting to initialize CloudKit schema...", level: .info)
                        try self.container.initializeCloudKitSchema()
                        Logger.shared.log("CloudKit schema initialization attempt completed", level: .info)
                    } catch {
                        // Check if it's the expected "no iCloud account" error
                        let nsError = error as NSError
                        if nsError.domain == NSCocoaErrorDomain && nsError.code == 134400 {
                            Logger.shared.log("CloudKit initialization skipped - no iCloud account (expected in simulator)", level: .info)
                        } else {
                            Logger.shared.log("Error initializing CloudKit schema: \(error.localizedDescription)", level: .warning)
                        }
                    }
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        Logger.shared.log("Set viewContext to automatically merge changes from parent", level: .info)
    }

    func saveContext() throws {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                Logger.shared.log("Successfully saved context", level: .info)
            } catch {
                Logger.shared.log("Error saving context: \(error.localizedDescription)", level: .error)
                throw error
            }
        }
    }
    
    func saveContext(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            do {
                try context.save()
                Logger.shared.log("Successfully saved context", level: .info)
            } catch {
                Logger.shared.log("Error saving context: \(error.localizedDescription)", level: .error)
                throw error
            }
        }
    }
}


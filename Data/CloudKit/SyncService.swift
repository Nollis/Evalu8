import Foundation
import CloudKit
import CoreData

protocol SyncServiceProtocol {
    func sync() async throws
    func initializeCloudKitSchema() throws
    func observeRemoteChanges()
}

class SyncService: SyncServiceProtocol {
    private let dataStore: DataStore
    private let cloudKitService: CloudKitServiceProtocol
    
    init(
        dataStore: DataStore = DataStore.shared,
        cloudKitService: CloudKitServiceProtocol = CloudKitService()
    ) {
        self.dataStore = dataStore
        self.cloudKitService = cloudKitService
    }
    
    func sync() async throws {
        if DevelopmentConfig.bypassCloudKit {
            Logger.shared.log("Bypassing CloudKit sync", level: .info)
            return
        }
        
        // Check account status
        let accountStatus = try await cloudKitService.checkAccountStatus()
        guard accountStatus == .available else {
            Logger.shared.log("CloudKit account not available, skipping sync", level: .warning)
            return
        }
        
        // CloudKit sync is handled automatically by NSPersistentCloudKitContainer
        // This method can be used to trigger manual sync or verify sync status
        Logger.shared.log("CloudKit sync initiated", level: .info)
        
        // The actual sync happens automatically via NSPersistentCloudKitContainer
        // We can add additional sync coordination logic here if needed
    }
    
    func initializeCloudKitSchema() throws {
        if DevelopmentConfig.bypassCloudKit {
            Logger.shared.log("Bypassing CloudKit schema initialization", level: .info)
            return
        }
        
        do {
            try dataStore.container.initializeCloudKitSchema()
            Logger.shared.log("CloudKit schema initialized successfully", level: .info)
        } catch {
            Logger.shared.log("Error initializing CloudKit schema: \(error.localizedDescription)", level: .error)
            throw ShareError.schemaValidationFailed(error.localizedDescription)
        }
    }
    
    func observeRemoteChanges() {
        // Set up notification observers for remote changes
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: dataStore.container.persistentStoreCoordinator,
            queue: .main
        ) { notification in
            Logger.shared.log("Remote change detected", level: .info)
            // Handle remote changes if needed
            // Core Data will automatically merge changes, but we can add custom logic here
        }
        
        Logger.shared.log("Started observing remote CloudKit changes", level: .info)
    }
}


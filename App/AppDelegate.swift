import UIKit
import CoreData
import CloudKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var dataStore: DataStore!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("AppDelegate: didFinishLaunchingWithOptions called")
        Logger.shared.log("AppDelegate: didFinishLaunchingWithOptions called", level: .info)
        
        // Defer DataStore initialization to avoid blocking
        Task { @MainActor in
            print("AppDelegate: Creating DataStore.shared (async)")
            do {
                dataStore = DataStore.shared
                print("AppDelegate: DataStore.shared created")
                
                // Ensure UUIDs for all existing decisions
                print("AppDelegate: Calling ensureUUIDsForExistingDecisions")
                ensureUUIDsForExistingDecisions()
                print("AppDelegate: ensureUUIDsForExistingDecisions completed")
            } catch {
                print("AppDelegate: Error initializing DataStore: \(error)")
            }
        }
        
        print("AppDelegate: Returning true")
        return true
    }
    
    func application(_ application: UIApplication,
                     userDidAcceptCloudKitShareWith shareMetadata: CKShare.Metadata) {
        Logger.shared.log("Received CloudKit share invitation", level: .info)
        
        let container = CKContainer(identifier: AppConstants.cloudKitContainerIdentifier)
        
        Task {
            do {
                try await container.accept(shareMetadata)
                Logger.shared.log("Successfully accepted share", level: .info)
            } catch {
                Logger.shared.log("Failed to accept share: \(error.localizedDescription)", level: .error)
            }
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Logger.shared.log("Received deep link: \(url.absoluteString)", level: .info)
        // Handle deep links here
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        Logger.shared.log("Received user activity: \(userActivity.activityType)", level: .info)
        
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            return self.application(application, open: url, options: [:])
        }
        
        return false
    }
    
    private func ensureUUIDsForExistingDecisions() {
        Logger.shared.log("Ensuring UUIDs for all decisions", level: .info)
        let context = dataStore.container.viewContext
        let fetchRequest: NSFetchRequest<Decision> = Decision.fetchRequest()
        
        do {
            let decisions = try context.fetch(fetchRequest)
            var modified = 0
            
            for decision in decisions {
                if decision.uuid == nil {
                    decision.uuid = UUID().uuidString
                    modified += 1
                    Logger.shared.log("Generated UUID for decision: \(decision.title ?? "Unknown")", level: .info)
                }
            }
            
            if modified > 0 {
                try context.save()
                Logger.shared.log("Saved UUIDs for \(modified) existing decisions", level: .info)
            } else {
                Logger.shared.log("All decisions already have UUIDs", level: .info)
            }
        } catch {
            Logger.shared.log("Error ensuring UUIDs: \(error.localizedDescription)", level: .error)
        }
    }
}


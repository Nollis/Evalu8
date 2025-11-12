import SwiftUI
import CoreData
import CloudKit

@main
struct Evalu8App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, DataStore.shared.container.viewContext)
                .onAppear {
                    Logger.shared.log("Evalu8App: ContentView appeared", level: .info)
                }
        }
    }
}


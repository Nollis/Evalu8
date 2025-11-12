import SwiftUI
import CoreData

@main
struct Evalu8App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, DataStore.shared.container.viewContext)
        }
    }
}


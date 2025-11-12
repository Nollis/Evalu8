import SwiftUI
import CoreData
import CloudKit

@main
struct Evalu8App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        Logger.shared.log("Evalu8App: App initializing", level: .info)
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack {
                    Text("App is Running!")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                        .padding()
                    
                    Text("If you see this, the app is working")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ContentView()
                        .environment(\.managedObjectContext, DataStore.shared.container.viewContext)
                        .onAppear {
                            Logger.shared.log("Evalu8App: ContentView appeared", level: .info)
                            print("Evalu8App: ContentView appeared (print)")
                        }
                }
            }
        }
    }
}


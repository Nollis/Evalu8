import SwiftUI
import CoreData
import CloudKit

@main
struct Evalu8App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        print("Evalu8App: App initializing")
        Logger.shared.log("Evalu8App: App initializing", level: .info)
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("App is Running!")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                        .padding()
                    
                    Text("If you see this, the app is working")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Test Button") {
                        print("Button tapped!")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    // Temporarily comment out ContentView to test
                    // ContentView()
                    //     .environment(\.managedObjectContext, DataStore.shared.container.viewContext)
                }
                .onAppear {
                    print("Evalu8App: WindowGroup appeared")
                    Logger.shared.log("Evalu8App: WindowGroup appeared", level: .info)
                }
            }
            .task {
                print("Evalu8App: Task started")
                // Try to access DataStore after view appears
                do {
                    let _ = DataStore.shared
                    print("Evalu8App: DataStore.shared accessed successfully")
                } catch {
                    print("Evalu8App: Error accessing DataStore: \(error)")
                }
            }
        }
    }
}


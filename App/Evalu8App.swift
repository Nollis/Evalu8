import SwiftUI

@main
struct Evalu8App: App {
    // Temporarily remove AppDelegate to test
    // @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        print("✅✅✅ Evalu8App: INIT CALLED")
        print("✅✅✅ Evalu8App: This MUST appear in console")
    }
    
    var body: some Scene {
        WindowGroup {
            Text("HELLO WORLD")
                .font(.largeTitle)
                .foregroundColor(.red)
                .padding()
                .background(Color.yellow)
                .onAppear {
                    print("✅✅✅ Text view appeared")
                }
        }
    }
}


import SwiftUI

@main
struct SecondClockApp: App {
    @StateObject private var settingsStore = ClockSettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
        }
    }
}

import SwiftUI

@main
struct SecondClockApp: App {
    @StateObject private var settingsStore = ClockSettingsStore()
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            rootView
                .environmentObject(settingsStore)
                .environmentObject(purchaseManager)
                .task {
                    await purchaseManager.start()
                }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        #if DEBUG && targetEnvironment(simulator)
        if let screenshotMode = ProcessInfo.processInfo.environment[
            "SECOND_CLOCK_SCREENSHOT_MODE"
        ] {
            AppStoreScreenshotRootView(mode: screenshotMode)
        } else {
            ContentView()
        }
        #else
        ContentView()
        #endif
    }
}

#if DEBUG
import SwiftUI
import UIKit

struct AppStoreScreenshotRootView: View {
    @EnvironmentObject private var settingsStore: ClockSettingsStore
    let mode: String

    var body: some View {
        Group {
            switch mode {
            case "settings", "settings-landscape":
                ContentView(initiallyShowsSettings: true)

            case "paywall", "paywall-landscape":
                ProPaywallView()

            default:
                ContentView()
            }
        }
        .onAppear {
            configureAppearance()
            if mode == "landscape" || mode.hasSuffix("-landscape") {
                requestLandscapeOrientation()
            }
        }
    }

    private func configureAppearance() {
        switch mode {
        case "clock-aurora", "clock-aurora-landscape", "landscape", "settings", "settings-landscape":
            settingsStore.preferences = ClockThemePreset.aurora.applying(
                to: settingsStore.preferences
            )
            settingsStore.preferences.fontDesign = .monospaced
            settingsStore.preferences.fontWeight = .bold
            settingsStore.preferences.displaySize = .large

        case "clock-ocean-landscape":
            settingsStore.preferences = ClockThemePreset.ocean.applying(
                to: settingsStore.preferences
            )
            settingsStore.preferences.fontDesign = .monospaced
            settingsStore.preferences.fontWeight = .bold
            settingsStore.preferences.displaySize = .large

        case "clock-sunset-landscape":
            settingsStore.preferences = ClockThemePreset.sunset.applying(
                to: settingsStore.preferences
            )
            settingsStore.preferences.fontDesign = .rounded
            settingsStore.preferences.fontWeight = .bold
            settingsStore.preferences.displaySize = .large

        default:
            settingsStore.preferences = .default
        }

        if mode == "clock-flip-landscape" {
            settingsStore.preferences = ClockThemePreset.nightSky.applying(
                to: settingsStore.preferences
            )
            settingsStore.preferences.layoutStyle = .flip
            settingsStore.preferences.displaySize = .large
        } else if mode == "clock-ring-landscape" {
            settingsStore.preferences = ClockThemePreset.ocean.applying(
                to: settingsStore.preferences
            )
            settingsStore.preferences.layoutStyle = .secondsRing
            settingsStore.preferences.displaySize = .large
        } else if mode == "clock-night-landscape" {
            settingsStore.preferences.layoutStyle = .secondsFocus
            settingsStore.preferences.nightMode = .on
            settingsStore.preferences.nightTextIntensity = 0.48
            settingsStore.preferences.displaySize = .large
        }
    }

    private func requestLandscapeOrientation() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else {
            return
        }

        scene.requestGeometryUpdate(
            .iOS(interfaceOrientations: .landscapeRight)
        )
    }
}
#endif

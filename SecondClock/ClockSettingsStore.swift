import Foundation
import SwiftUI
import WidgetKit

@MainActor
final class ClockSettingsStore: ObservableObject {
    @Published var preferences: ClockPreferences {
        didSet {
            persistChanges()
        }
    }

    @Published private(set) var backgroundImageRevision = UUID()

    init() {
        preferences = SharedClockStorage.loadPreferences()
    }

    var isAppGroupAvailable: Bool {
        SharedClockStorage.isAppGroupAvailable
    }

    func saveBackgroundImage(_ originalData: Data) throws {
        let optimizedData = try PhotoBackgroundManager.optimizedJPEGData(from: originalData)
        try SharedClockStorage.saveBackgroundImageData(optimizedData)
        backgroundImageRevision = UUID()

        if preferences.backgroundStyle == .photo {
            persistChanges()
        } else {
            preferences.backgroundStyle = .photo
        }
    }

    func removeBackgroundImage() {
        SharedClockStorage.removeBackgroundImage()
        backgroundImageRevision = UUID()

        if preferences.backgroundStyle == .photo {
            preferences.backgroundStyle = .gradient
        } else {
            WidgetCenter.shared.reloadTimelines(ofKind: SharedClockStorage.widgetKind)
        }
    }

    func restoreDefaults() {
        SharedClockStorage.removeBackgroundImage()
        backgroundImageRevision = UUID()
        preferences = .default
    }

    private func persistChanges() {
        SharedClockStorage.savePreferences(preferences)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedClockStorage.widgetKind)
    }
}

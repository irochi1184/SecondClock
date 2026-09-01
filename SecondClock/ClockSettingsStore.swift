import Foundation
import SwiftUI
import WidgetKit

@MainActor
final class ClockSettingsStore: ObservableObject {
    @Published var preferences: ClockPreferences {
        didSet {
            guard !isSwitchingPreset else { return }
            updateActivePresetAndPersist()
        }
    }

    @Published private(set) var presets: [ClockPreset]
    @Published private(set) var activePresetID: UUID
    @Published private(set) var backgroundImageRevision = UUID()
    private var isSwitchingPreset = false

    init() {
        let collection = SharedClockStorage.loadPresetCollection()
        presets = collection.presets
        activePresetID = collection.activePresetID
        preferences = collection.activePreferences
    }

    var isAppGroupAvailable: Bool {
        SharedClockStorage.isAppGroupAvailable
    }

    var activePresetName: String {
        presets.first(where: { $0.id == activePresetID })?.name ?? "プリセット"
    }

    func effectivePreferences(isProUnlocked: Bool) -> ClockPreferences {
        preferences.applying(
            accessLevel: ClockAccessLevel(isProUnlocked: isProUnlocked)
        )
    }

    func selectPreset(id: UUID) {
        guard id != activePresetID,
              let preset = presets.first(where: { $0.id == id })
        else {
            return
        }

        isSwitchingPreset = true
        activePresetID = id
        preferences = preset.preferences
        isSwitchingPreset = false
        persistPresetCollection()
    }

    @discardableResult
    func selectAdjacentPreset(forward: Bool) -> Bool {
        guard presets.count > 1,
              let currentIndex = presets.firstIndex(where: { $0.id == activePresetID })
        else {
            return false
        }

        let offset = forward ? 1 : -1
        let nextIndex = (currentIndex + offset + presets.count) % presets.count
        selectPreset(id: presets[nextIndex].id)
        return true
    }

    @discardableResult
    func addPreset(isProUnlocked: Bool) -> Bool {
        guard ClockPresetAccessPolicy.canCreatePreset(
            currentCount: presets.count,
            isProUnlocked: isProUnlocked
        ) else {
            return false
        }

        let newPreset = ClockPreset(
            name: nextPresetName(),
            preferences: preferences
        )
        presets.append(newPreset)
        selectPreset(id: newPreset.id)
        return true
    }

    func deleteActivePreset() {
        guard presets.count > 1,
              let currentIndex = presets.firstIndex(where: { $0.id == activePresetID })
        else {
            return
        }

        presets.remove(at: currentIndex)
        let nextIndex = min(currentIndex, presets.count - 1)
        let nextPreset = presets[nextIndex]

        isSwitchingPreset = true
        activePresetID = nextPreset.id
        preferences = nextPreset.preferences
        isSwitchingPreset = false
        persistPresetCollection()
    }

    func saveBackgroundImage(_ originalData: Data) throws {
        let optimizedData = try PhotoBackgroundManager.optimizedJPEGData(from: originalData)
        try SharedClockStorage.saveBackgroundImageData(optimizedData)
        backgroundImageRevision = UUID()

        if preferences.backgroundStyle == .photo {
            persistPresetCollection()
        } else {
            preferences.backgroundStyle = .photo
        }
    }

    func removeBackgroundImage() {
        SharedClockStorage.removeBackgroundImage()
        backgroundImageRevision = UUID()

        for index in presets.indices where presets[index].preferences.backgroundStyle == .photo {
            presets[index].preferences.backgroundStyle = .gradient
        }

        isSwitchingPreset = true
        preferences = presets.first(where: { $0.id == activePresetID })?.preferences
            ?? .default
        isSwitchingPreset = false
        persistPresetCollection()
    }

    func restoreDefaults() {
        SharedClockStorage.removeBackgroundImage()
        backgroundImageRevision = UUID()
        let collection = ClockPresetCollection.initial(preferences: .default)

        isSwitchingPreset = true
        presets = collection.presets
        activePresetID = collection.activePresetID
        preferences = collection.activePreferences
        isSwitchingPreset = false
        persistPresetCollection()
    }

    private func updateActivePresetAndPersist() {
        guard let index = presets.firstIndex(where: { $0.id == activePresetID }) else {
            return
        }

        presets[index].preferences = preferences
        persistPresetCollection()
    }

    private func persistPresetCollection() {
        SharedClockStorage.savePresetCollection(
            ClockPresetCollection(
                presets: presets,
                activePresetID: activePresetID
            )
        )
        WidgetCenter.shared.reloadTimelines(ofKind: SharedClockStorage.widgetKind)
    }

    private func nextPresetName() -> String {
        var number = 1
        let existingNames = Set(presets.map(\.name))

        while existingNames.contains("プリセット \(number)") {
            number += 1
        }

        return "プリセット \(number)"
    }
}

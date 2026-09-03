import AppIntents
import Foundation
import ImageIO
import UIKit
import WidgetKit

enum SharedClockStorage {
    static let appGroupIdentifier = "group.com.irochi.SecondClock"
    static let widgetKind = "SecondClockWidget"

    private static let preferencesKey = "clock.preferences.v1"
    private static let presetCollectionKey = "clock.presets.v1"
    private static let presetScheduleKey = "clock.preset.schedule.v1"
    private static let proEntitlementCacheKey = "purchase.pro.entitlement.cache.v1"
    private static let backgroundImageName = "clock-background.jpg"

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    static var isAppGroupAvailable: Bool {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) != nil
    }

    static func loadPreferences() -> ClockPreferences {
        if let collection = decodedPresetCollection() {
            return collection.activePreferences
        }

        return loadLegacyPreferences()
    }

    static func loadPresetCollection() -> ClockPresetCollection {
        decodedPresetCollection()
            ?? .initial(preferences: loadLegacyPreferences())
    }

    static func savePresetCollection(_ collection: ClockPresetCollection) {
        guard !collection.presets.isEmpty,
              collection.presets.contains(where: { $0.id == collection.activePresetID }),
              let data = try? JSONEncoder().encode(collection)
        else {
            return
        }

        sharedDefaults.set(data, forKey: presetCollectionKey)
        savePreferences(collection.activePreferences)
    }

    static func loadPresetSchedule() -> ClockPresetSchedule {
        guard let data = sharedDefaults.data(forKey: presetScheduleKey),
              let schedule = try? JSONDecoder().decode(ClockPresetSchedule.self, from: data)
        else {
            return .default
        }
        return schedule
    }

    static func savePresetSchedule(_ schedule: ClockPresetSchedule) {
        guard let data = try? JSONEncoder().encode(schedule) else { return }
        sharedDefaults.set(data, forKey: presetScheduleKey)
    }

    private static func loadLegacyPreferences() -> ClockPreferences {
        guard let data = sharedDefaults.data(forKey: preferencesKey),
              let preferences = try? JSONDecoder().decode(ClockPreferences.self, from: data)
        else {
            return .default
        }

        return preferences
    }

    private static func decodedPresetCollection() -> ClockPresetCollection? {
        guard let data = sharedDefaults.data(forKey: presetCollectionKey),
              let collection = try? JSONDecoder().decode(
                ClockPresetCollection.self,
                from: data
              ),
              !collection.presets.isEmpty,
              collection.presets.contains(where: { $0.id == collection.activePresetID })
        else {
            return nil
        }

        return collection
    }

    static func savePreferences(_ preferences: ClockPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        sharedDefaults.set(data, forKey: preferencesKey)
    }

    static func loadEffectivePreferences(
        at date: Date = .now,
        presetID: UUID? = nil
    ) -> ClockPreferences {
        resolvedPreset(at: date, presetID: presetID).preferences.applying(
            accessLevel: ClockAccessLevel(isProUnlocked: isProEntitlementCached)
        )
    }

    static func resolvedPreset(at date: Date = .now, presetID: UUID? = nil) -> ClockPreset {
        let collection = loadPresetCollection()

        if let presetID,
           let selected = collection.presets.first(where: { $0.id == presetID }) {
            return selected
        }

        if isProEntitlementCached {
            let schedule = loadPresetSchedule()
            if let scheduledID = schedule.presetID(at: date),
               let scheduled = collection.presets.first(where: { $0.id == scheduledID }) {
                return scheduled
            }
        }

        return collection.presets.first(where: { $0.id == collection.activePresetID })
            ?? collection.presets[0]
    }

    @discardableResult
    static func switchActivePreset(forward: Bool) -> ClockPresetCollection {
        var collection = loadPresetCollection()
        guard collection.presets.count > 1,
              let currentIndex = collection.presets.firstIndex(where: {
                  $0.id == collection.activePresetID
              })
        else {
            return collection
        }

        let offset = forward ? 1 : -1
        let nextIndex = (currentIndex + offset + collection.presets.count)
            % collection.presets.count
        collection.activePresetID = collection.presets[nextIndex].id
        savePresetCollection(collection)
        return collection
    }

    static var isProEntitlementCached: Bool {
        sharedDefaults.bool(forKey: proEntitlementCacheKey)
    }

    static func cacheProEntitlement(_ isUnlocked: Bool) {
        sharedDefaults.set(isUnlocked, forKey: proEntitlementCacheKey)
    }

    static var backgroundImageURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(backgroundImageName, isDirectory: false)
    }

    static func saveBackgroundImageData(_ data: Data) throws {
        guard let url = backgroundImageURL else {
            throw SharedClockStorageError.appGroupUnavailable
        }

        try data.write(to: url, options: .atomic)
    }

    static func loadBackgroundImage() -> UIImage? {
        guard let url = backgroundImageURL else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static var backgroundImageModificationDate: Date? {
        guard let url = backgroundImageURL else { return nil }
        return try? url.resourceValues(forKeys: [.contentModificationDateKey])
            .contentModificationDate
    }

    static func loadWidgetBackgroundImage() -> UIImage? {
        guard let url = backgroundImageURL,
              let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1_024
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            return nil
        }

        return UIImage(cgImage: image)
    }

    static func removeBackgroundImage() {
        guard let url = backgroundImageURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

struct ClockPresetEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "時計プリセット")
    static var defaultQuery: ClockPresetEntityQuery { ClockPresetEntityQuery() }

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct ClockPresetEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ClockPresetEntity] {
        guard SharedClockStorage.isProEntitlementCached else { return [] }
        let identifiers = Set(identifiers)
        return SharedClockStorage.loadPresetCollection().presets.compactMap { preset in
            let id = preset.id.uuidString
            guard identifiers.contains(id) else { return nil }
            return ClockPresetEntity(id: id, name: preset.name)
        }
    }

    func suggestedEntities() async throws -> [ClockPresetEntity] {
        guard SharedClockStorage.isProEntitlementCached else { return [] }
        return SharedClockStorage.loadPresetCollection().presets.map {
            ClockPresetEntity(id: $0.id.uuidString, name: $0.name)
        }
    }
}

struct ClockWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "時計ウィジェット"
    static var description = IntentDescription("表示するプリセットを選択できます。")

    @Parameter(title: "固定するプリセット")
    var preset: ClockPresetEntity?

    init() {}
}

enum ClockPresetSwitchDirection: String, AppEnum {
    case previous
    case next

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "切替方向")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .previous: "前へ",
        .next: "次へ"
    ]
}

struct SwitchClockPresetIntent: AppIntent {
    static var title: LocalizedStringResource = "時計プリセットを切り替える"
    static var description = IntentDescription("使用中の時計プリセットを前後に切り替えます。")
    static var openAppWhenRun = false

    @Parameter(title: "方向")
    var direction: ClockPresetSwitchDirection

    init() {
        direction = .next
    }

    init(direction: ClockPresetSwitchDirection) {
        self.direction = direction
    }

    func perform() async throws -> some IntentResult {
        SharedClockStorage.switchActivePreset(forward: direction == .next)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedClockStorage.widgetKind)
        return .result()
    }
}

enum SharedClockStorageError: LocalizedError {
    case appGroupUnavailable

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            "App Groupを利用できません。Xcodeの署名設定を確認してください。"
        }
    }
}

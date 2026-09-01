import Foundation
import ImageIO
import UIKit

enum SharedClockStorage {
    static let appGroupIdentifier = "group.com.irochi.SecondClock"
    static let widgetKind = "SecondClockWidget"

    private static let preferencesKey = "clock.preferences.v1"
    private static let presetCollectionKey = "clock.presets.v1"
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

    static func loadEffectivePreferences() -> ClockPreferences {
        loadPreferences().applying(
            accessLevel: ClockAccessLevel(isProUnlocked: isProEntitlementCached)
        )
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

enum SharedClockStorageError: LocalizedError {
    case appGroupUnavailable

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            "App Groupを利用できません。Xcodeの署名設定を確認してください。"
        }
    }
}

import Foundation
import ImageIO
import UIKit

enum SharedClockStorage {
    static let appGroupIdentifier = "group.com.irochi.SecondClock"
    static let widgetKind = "SecondClockWidget"

    private static let preferencesKey = "clock.preferences.v1"
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
        guard let data = sharedDefaults.data(forKey: preferencesKey),
              let preferences = try? JSONDecoder().decode(ClockPreferences.self, from: data)
        else {
            return .default
        }

        return preferences
    }

    static func savePreferences(_ preferences: ClockPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        sharedDefaults.set(data, forKey: preferencesKey)
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

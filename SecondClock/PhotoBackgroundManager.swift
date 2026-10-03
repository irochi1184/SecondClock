import Foundation
import ImageIO
import UIKit

enum PhotoBackgroundManager {
    private static let maximumDimension: CGFloat = 1_600

    /// Decodes straight to a downsampled bitmap. Decoding the full image first
    /// (e.g. a 48MP photo) needs hundreds of MB and could freeze or crash the app.
    /// Safe to call off the main thread.
    static func optimizedJPEGData(from data: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw PhotoBackgroundError.invalidImage
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumDimension
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            throw PhotoBackgroundError.invalidImage
        }

        guard let jpegData = UIImage(cgImage: image).jpegData(compressionQuality: 0.86) else {
            throw PhotoBackgroundError.encodingFailed
        }

        return jpegData
    }
}

enum PhotoBackgroundError: LocalizedError {
    case invalidImage
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            "選択した画像を読み込めませんでした。"
        case .encodingFailed:
            "背景画像を保存用に変換できませんでした。"
        }
    }
}

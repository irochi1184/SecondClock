import Foundation
import UIKit

enum PhotoBackgroundManager {
    private static let maximumDimension: CGFloat = 1_600

    static func optimizedJPEGData(from data: Data) throws -> Data {
        guard let image = UIImage(data: data) else {
            throw PhotoBackgroundError.invalidImage
        }

        let originalSize = image.size
        let longestSide = max(originalSize.width, originalSize.height)
        let scale = min(1, maximumDimension / longestSide)
        let targetSize = CGSize(
            width: max(1, floor(originalSize.width * scale)),
            height: max(1, floor(originalSize.height * scale))
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let jpegData = resizedImage.jpegData(compressionQuality: 0.86) else {
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

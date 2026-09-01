import SwiftUI
import UIKit

enum ClockBackgroundStyle: String, Codable, CaseIterable, Identifiable {
    case system
    case solid
    case gradient
    case photo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "システム"
        case .solid: "単色"
        case .gradient: "グラデーション"
        case .photo: "写真"
        }
    }
}

enum ClockDisplaySize: String, Codable, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: "小"
        case .medium: "標準"
        case .large: "大"
        }
    }

    var scale: CGFloat {
        switch self {
        case .small: 0.78
        case .medium: 1
        case .large: 1.2
        }
    }
}

enum ClockGradientStyle: String, Codable, CaseIterable, Identifiable {
    case diagonalDown
    case diagonalUp
    case horizontal
    case vertical
    case radial

    var id: String { rawValue }

    var title: String {
        switch self {
        case .diagonalDown: "左上 → 右下"
        case .diagonalUp: "左下 → 右上"
        case .horizontal: "左 → 右"
        case .vertical: "上 → 下"
        case .radial: "中央 → 外側"
        }
    }
}

enum ClockFontDesign: String, Codable, CaseIterable, Identifiable {
    case rounded
    case standard
    case monospaced
    case serif

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rounded: "丸み"
        case .standard: "標準"
        case .monospaced: "等幅"
        case .serif: "セリフ"
        }
    }

    var swiftUIFontDesign: Font.Design {
        switch self {
        case .rounded: .rounded
        case .standard: .default
        case .monospaced: .monospaced
        case .serif: .serif
        }
    }
}

enum ClockFontWeight: String, Codable, CaseIterable, Identifiable {
    case regular
    case medium
    case bold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .regular: "標準"
        case .medium: "中太"
        case .bold: "太字"
        }
    }

    var swiftUIFontWeight: Font.Weight {
        switch self {
        case .regular: .regular
        case .medium: .medium
        case .bold: .bold
        }
    }
}

struct RGBAColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    static let white = RGBAColor(red: 1, green: 1, blue: 1, alpha: 1)
    static let midnight = RGBAColor(red: 0.05, green: 0.07, blue: 0.14, alpha: 1)
    static let indigo = RGBAColor(red: 0.22, green: 0.18, blue: 0.55, alpha: 1)
    static let blue = RGBAColor(red: 0.05, green: 0.42, blue: 0.82, alpha: 1)

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(_ color: Color) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            self.init(
                red: Double(red),
                green: Double(green),
                blue: Double(blue),
                alpha: Double(alpha)
            )
        } else {
            self = .white
        }
    }
}

struct ClockPreferences: Codable, Equatable {
    var showDate: Bool
    var displaySize: ClockDisplaySize
    var fontDesign: ClockFontDesign
    var fontWeight: ClockFontWeight
    var textColor: RGBAColor
    var backgroundStyle: ClockBackgroundStyle
    var solidColor: RGBAColor
    var gradientStartColor: RGBAColor
    var gradientEndColor: RGBAColor
    var gradientStyle: ClockGradientStyle
    var photoDimming: Double

    static let `default` = ClockPreferences(
        showDate: true,
        displaySize: .medium,
        fontDesign: .rounded,
        fontWeight: .medium,
        textColor: .white,
        backgroundStyle: .gradient,
        solidColor: .midnight,
        gradientStartColor: .indigo,
        gradientEndColor: .blue,
        gradientStyle: .diagonalDown,
        photoDimming: 0.28
    )

    private enum CodingKeys: String, CodingKey {
        case showDate
        case displaySize
        case fontDesign
        case fontWeight
        case textColor
        case backgroundStyle
        case solidColor
        case gradientStartColor
        case gradientEndColor
        case gradientStyle
        case photoDimming
    }

    init(
        showDate: Bool,
        displaySize: ClockDisplaySize,
        fontDesign: ClockFontDesign,
        fontWeight: ClockFontWeight,
        textColor: RGBAColor,
        backgroundStyle: ClockBackgroundStyle,
        solidColor: RGBAColor,
        gradientStartColor: RGBAColor,
        gradientEndColor: RGBAColor,
        gradientStyle: ClockGradientStyle,
        photoDimming: Double
    ) {
        self.showDate = showDate
        self.displaySize = displaySize
        self.fontDesign = fontDesign
        self.fontWeight = fontWeight
        self.textColor = textColor
        self.backgroundStyle = backgroundStyle
        self.solidColor = solidColor
        self.gradientStartColor = gradientStartColor
        self.gradientEndColor = gradientEndColor
        self.gradientStyle = gradientStyle
        self.photoDimming = photoDimming
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ClockPreferences.default

        showDate = try values.decodeIfPresent(Bool.self, forKey: .showDate)
            ?? defaults.showDate
        displaySize = try values.decodeIfPresent(ClockDisplaySize.self, forKey: .displaySize)
            ?? defaults.displaySize
        fontDesign = try values.decodeIfPresent(ClockFontDesign.self, forKey: .fontDesign)
            ?? defaults.fontDesign
        fontWeight = try values.decodeIfPresent(ClockFontWeight.self, forKey: .fontWeight)
            ?? defaults.fontWeight
        textColor = try values.decodeIfPresent(RGBAColor.self, forKey: .textColor)
            ?? defaults.textColor
        backgroundStyle = try values.decodeIfPresent(ClockBackgroundStyle.self, forKey: .backgroundStyle)
            ?? defaults.backgroundStyle
        solidColor = try values.decodeIfPresent(RGBAColor.self, forKey: .solidColor)
            ?? defaults.solidColor
        gradientStartColor = try values.decodeIfPresent(RGBAColor.self, forKey: .gradientStartColor)
            ?? defaults.gradientStartColor
        gradientEndColor = try values.decodeIfPresent(RGBAColor.self, forKey: .gradientEndColor)
            ?? defaults.gradientEndColor
        gradientStyle = try values.decodeIfPresent(ClockGradientStyle.self, forKey: .gradientStyle)
            ?? defaults.gradientStyle
        photoDimming = try values.decodeIfPresent(Double.self, forKey: .photoDimming)
            ?? defaults.photoDimming
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(showDate, forKey: .showDate)
        try values.encode(displaySize, forKey: .displaySize)
        try values.encode(fontDesign, forKey: .fontDesign)
        try values.encode(fontWeight, forKey: .fontWeight)
        try values.encode(textColor, forKey: .textColor)
        try values.encode(backgroundStyle, forKey: .backgroundStyle)
        try values.encode(solidColor, forKey: .solidColor)
        try values.encode(gradientStartColor, forKey: .gradientStartColor)
        try values.encode(gradientEndColor, forKey: .gradientEndColor)
        try values.encode(gradientStyle, forKey: .gradientStyle)
        try values.encode(photoDimming, forKey: .photoDimming)
    }
}

struct ClockPreset: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var preferences: ClockPreferences

    init(
        id: UUID = UUID(),
        name: String,
        preferences: ClockPreferences
    ) {
        self.id = id
        self.name = name
        self.preferences = preferences
    }
}

struct ClockPresetCollection: Codable, Equatable {
    var presets: [ClockPreset]
    var activePresetID: UUID

    static func initial(preferences: ClockPreferences) -> ClockPresetCollection {
        let preset = ClockPreset(name: "プリセット 1", preferences: preferences)
        return ClockPresetCollection(presets: [preset], activePresetID: preset.id)
    }

    var activePreferences: ClockPreferences {
        presets.first(where: { $0.id == activePresetID })?.preferences
            ?? presets.first?.preferences
            ?? .default
    }
}

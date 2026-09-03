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

enum ClockLayoutStyle: String, Codable, CaseIterable, Identifiable {
    case classic
    case secondsFocus
    case flip
    case secondsRing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: "クラシック"
        case .secondsFocus: "秒を強調"
        case .flip: "フリップ"
        case .secondsRing: "秒リング"
        }
    }

    var systemImage: String {
        switch self {
        case .classic: "clock"
        case .secondsFocus: "textformat.size.larger"
        case .flip: "rectangle.split.3x1"
        case .secondsRing: "circle.dotted.circle"
        }
    }
}

enum ClockNightMode: String, Codable, CaseIterable, Identifiable {
    case off
    case on
    case scheduled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: "オフ"
        case .on: "オン"
        case .scheduled: "時間指定"
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

enum ClockBackgroundMotion: String, Codable, CaseIterable, Identifiable {
    case none
    case flowingGradient
    case aurora
    case waves

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "静止"
        case .flowingGradient: "流れるグラデーション"
        case .aurora: "オーロラ"
        case .waves: "波"
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
    var layoutStyle: ClockLayoutStyle
    var fontDesign: ClockFontDesign
    var fontWeight: ClockFontWeight
    var textColor: RGBAColor
    var backgroundStyle: ClockBackgroundStyle
    var solidColor: RGBAColor
    var gradientStartColor: RGBAColor
    var gradientEndColor: RGBAColor
    var gradientStyle: ClockGradientStyle
    var backgroundMotion: ClockBackgroundMotion
    var animationSpeed: Double
    var animationIntensity: Double
    var photoDimming: Double
    var keepsScreenAwake: Bool
    var nightMode: ClockNightMode
    var nightStartMinutes: Int
    var nightEndMinutes: Int
    var nightTextIntensity: Double
    var burnInProtection: Bool

    static let `default` = ClockPreferences(
        showDate: true,
        displaySize: .medium,
        layoutStyle: .classic,
        fontDesign: .rounded,
        fontWeight: .medium,
        textColor: .white,
        backgroundStyle: .gradient,
        solidColor: .midnight,
        gradientStartColor: .indigo,
        gradientEndColor: .blue,
        gradientStyle: .diagonalDown,
        backgroundMotion: .flowingGradient,
        animationSpeed: 1,
        animationIntensity: 0.65,
        photoDimming: 0.28,
        keepsScreenAwake: true,
        nightMode: .off,
        nightStartMinutes: 22 * 60,
        nightEndMinutes: 7 * 60,
        nightTextIntensity: 0.55,
        burnInProtection: true
    )

    private enum CodingKeys: String, CodingKey {
        case showDate
        case displaySize
        case layoutStyle
        case fontDesign
        case fontWeight
        case textColor
        case backgroundStyle
        case solidColor
        case gradientStartColor
        case gradientEndColor
        case gradientStyle
        case backgroundMotion
        case animationSpeed
        case animationIntensity
        case photoDimming
        case keepsScreenAwake
        case nightMode
        case nightStartMinutes
        case nightEndMinutes
        case nightTextIntensity
        case burnInProtection
    }

    init(
        showDate: Bool,
        displaySize: ClockDisplaySize,
        layoutStyle: ClockLayoutStyle = .classic,
        fontDesign: ClockFontDesign,
        fontWeight: ClockFontWeight,
        textColor: RGBAColor,
        backgroundStyle: ClockBackgroundStyle,
        solidColor: RGBAColor,
        gradientStartColor: RGBAColor,
        gradientEndColor: RGBAColor,
        gradientStyle: ClockGradientStyle,
        backgroundMotion: ClockBackgroundMotion = .flowingGradient,
        animationSpeed: Double = 1,
        animationIntensity: Double = 0.65,
        photoDimming: Double,
        keepsScreenAwake: Bool = true,
        nightMode: ClockNightMode = .off,
        nightStartMinutes: Int = 22 * 60,
        nightEndMinutes: Int = 7 * 60,
        nightTextIntensity: Double = 0.55,
        burnInProtection: Bool = true
    ) {
        self.showDate = showDate
        self.displaySize = displaySize
        self.layoutStyle = layoutStyle
        self.fontDesign = fontDesign
        self.fontWeight = fontWeight
        self.textColor = textColor
        self.backgroundStyle = backgroundStyle
        self.solidColor = solidColor
        self.gradientStartColor = gradientStartColor
        self.gradientEndColor = gradientEndColor
        self.gradientStyle = gradientStyle
        self.backgroundMotion = backgroundMotion
        self.animationSpeed = animationSpeed
        self.animationIntensity = animationIntensity
        self.photoDimming = photoDimming
        self.keepsScreenAwake = keepsScreenAwake
        self.nightMode = nightMode
        self.nightStartMinutes = nightStartMinutes
        self.nightEndMinutes = nightEndMinutes
        self.nightTextIntensity = nightTextIntensity
        self.burnInProtection = burnInProtection
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ClockPreferences.default

        showDate = try values.decodeIfPresent(Bool.self, forKey: .showDate)
            ?? defaults.showDate
        displaySize = try values.decodeIfPresent(ClockDisplaySize.self, forKey: .displaySize)
            ?? defaults.displaySize
        layoutStyle = try values.decodeIfPresent(ClockLayoutStyle.self, forKey: .layoutStyle)
            ?? defaults.layoutStyle
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
        backgroundMotion = try values.decodeIfPresent(
            ClockBackgroundMotion.self,
            forKey: .backgroundMotion
        ) ?? defaults.backgroundMotion
        animationSpeed = try values.decodeIfPresent(Double.self, forKey: .animationSpeed)
            ?? defaults.animationSpeed
        animationIntensity = try values.decodeIfPresent(
            Double.self,
            forKey: .animationIntensity
        ) ?? defaults.animationIntensity
        photoDimming = try values.decodeIfPresent(Double.self, forKey: .photoDimming)
            ?? defaults.photoDimming
        keepsScreenAwake = try values.decodeIfPresent(Bool.self, forKey: .keepsScreenAwake)
            ?? defaults.keepsScreenAwake
        nightMode = try values.decodeIfPresent(ClockNightMode.self, forKey: .nightMode)
            ?? defaults.nightMode
        nightStartMinutes = try values.decodeIfPresent(Int.self, forKey: .nightStartMinutes)
            ?? defaults.nightStartMinutes
        nightEndMinutes = try values.decodeIfPresent(Int.self, forKey: .nightEndMinutes)
            ?? defaults.nightEndMinutes
        nightTextIntensity = try values.decodeIfPresent(Double.self, forKey: .nightTextIntensity)
            ?? defaults.nightTextIntensity
        burnInProtection = try values.decodeIfPresent(Bool.self, forKey: .burnInProtection)
            ?? defaults.burnInProtection
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(showDate, forKey: .showDate)
        try values.encode(displaySize, forKey: .displaySize)
        try values.encode(layoutStyle, forKey: .layoutStyle)
        try values.encode(fontDesign, forKey: .fontDesign)
        try values.encode(fontWeight, forKey: .fontWeight)
        try values.encode(textColor, forKey: .textColor)
        try values.encode(backgroundStyle, forKey: .backgroundStyle)
        try values.encode(solidColor, forKey: .solidColor)
        try values.encode(gradientStartColor, forKey: .gradientStartColor)
        try values.encode(gradientEndColor, forKey: .gradientEndColor)
        try values.encode(gradientStyle, forKey: .gradientStyle)
        try values.encode(backgroundMotion, forKey: .backgroundMotion)
        try values.encode(animationSpeed, forKey: .animationSpeed)
        try values.encode(animationIntensity, forKey: .animationIntensity)
        try values.encode(photoDimming, forKey: .photoDimming)
        try values.encode(keepsScreenAwake, forKey: .keepsScreenAwake)
        try values.encode(nightMode, forKey: .nightMode)
        try values.encode(nightStartMinutes, forKey: .nightStartMinutes)
        try values.encode(nightEndMinutes, forKey: .nightEndMinutes)
        try values.encode(nightTextIntensity, forKey: .nightTextIntensity)
        try values.encode(burnInProtection, forKey: .burnInProtection)
    }

    func isNightModeActive(at date: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        switch nightMode {
        case .off:
            return false
        case .on:
            return true
        case .scheduled:
            let components = calendar.dateComponents([.hour, .minute], from: date)
            let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            let start = min(max(nightStartMinutes, 0), 1_439)
            let end = min(max(nightEndMinutes, 0), 1_439)

            if start < end {
                return minutes >= start && minutes < end
            }
            return minutes >= start || minutes < end
        }
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

struct ClockPresetSchedule: Codable, Equatable {
    var isEnabled: Bool
    var dayPresetID: UUID?
    var nightPresetID: UUID?
    var dayStartMinutes: Int
    var nightStartMinutes: Int

    static let `default` = ClockPresetSchedule(
        isEnabled: false,
        dayPresetID: nil,
        nightPresetID: nil,
        dayStartMinutes: 7 * 60,
        nightStartMinutes: 22 * 60
    )

    func presetID(at date: Date, calendar: Calendar = .autoupdatingCurrent) -> UUID? {
        guard isEnabled else { return nil }
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let dayStart = min(max(dayStartMinutes, 0), 1_439)
        let nightStart = min(max(nightStartMinutes, 0), 1_439)

        if dayStart < nightStart {
            return minutes >= dayStart && minutes < nightStart
                ? dayPresetID
                : nightPresetID
        }
        return minutes >= nightStart && minutes < dayStart
            ? nightPresetID
            : dayPresetID
    }
}

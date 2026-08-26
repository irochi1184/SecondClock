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
    var fontDesign: ClockFontDesign
    var fontWeight: ClockFontWeight
    var textColor: RGBAColor
    var backgroundStyle: ClockBackgroundStyle
    var solidColor: RGBAColor
    var gradientStartColor: RGBAColor
    var gradientEndColor: RGBAColor
    var photoDimming: Double

    static let `default` = ClockPreferences(
        showDate: true,
        fontDesign: .rounded,
        fontWeight: .medium,
        textColor: .white,
        backgroundStyle: .gradient,
        solidColor: .midnight,
        gradientStartColor: .indigo,
        gradientEndColor: .blue,
        photoDimming: 0.28
    )
}

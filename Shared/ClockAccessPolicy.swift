import Foundation

enum ClockAccessLevel: Equatable {
    case free
    case pro

    init(isProUnlocked: Bool) {
        self = isProUnlocked ? .pro : .free
    }
}

extension ClockFontDesign {
    var requiresPro: Bool {
        false
    }
}

extension ClockFontWeight {
    var requiresPro: Bool {
        false
    }
}

extension ClockBackgroundStyle {
    var requiresPro: Bool {
        self == .photo
    }
}

extension ClockPreferences {
    func applying(accessLevel: ClockAccessLevel) -> ClockPreferences {
        guard accessLevel == .free else { return self }

        var effective = self

        switch effective.backgroundStyle {
        case .system, .solid, .gradient:
            break

        case .photo:
            effective.backgroundStyle = .gradient
            effective.gradientStartColor = ClockPreferences.default.gradientStartColor
            effective.gradientEndColor = ClockPreferences.default.gradientEndColor
        }

        return effective
    }
}

enum ClockThemePreset: String, CaseIterable, Identifiable {
    case aurora
    case sunset
    case ocean
    case sakura
    case nightSky

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aurora: "オーロラ"
        case .sunset: "夕焼け"
        case .ocean: "オーシャン"
        case .sakura: "桜"
        case .nightSky: "夜空"
        }
    }

    var requiresPro: Bool {
        switch self {
        case .aurora, .ocean:
            false
        case .sunset, .sakura, .nightSky:
            true
        }
    }

    var colors: [RGBAColor] {
        switch self {
        case .aurora:
            [
                RGBAColor(red: 0.07, green: 0.12, blue: 0.28),
                RGBAColor(red: 0.16, green: 0.72, blue: 0.60)
            ]
        case .sunset:
            [
                RGBAColor(red: 0.52, green: 0.10, blue: 0.30),
                RGBAColor(red: 0.96, green: 0.45, blue: 0.18)
            ]
        case .ocean:
            [
                RGBAColor(red: 0.01, green: 0.18, blue: 0.38),
                RGBAColor(red: 0.04, green: 0.62, blue: 0.84)
            ]
        case .sakura:
            [
                RGBAColor(red: 0.38, green: 0.15, blue: 0.43),
                RGBAColor(red: 0.94, green: 0.46, blue: 0.62)
            ]
        case .nightSky:
            [
                RGBAColor(red: 0.01, green: 0.02, blue: 0.08),
                RGBAColor(red: 0.18, green: 0.16, blue: 0.48)
            ]
        }
    }

    func applying(to preferences: ClockPreferences) -> ClockPreferences {
        var updated = preferences
        updated.backgroundStyle = .gradient
        updated.gradientStartColor = colors[0]
        updated.gradientEndColor = colors[1]
        updated.textColor = .white
        return updated
    }
}

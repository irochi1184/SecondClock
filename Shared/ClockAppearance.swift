import SwiftUI
import WidgetKit

struct ClockBackgroundView: View {
    let preferences: ClockPreferences
    let loadsWidgetSizedPhoto: Bool

    init(preferences: ClockPreferences, loadsWidgetSizedPhoto: Bool = false) {
        self.preferences = preferences
        self.loadsWidgetSizedPhoto = loadsWidgetSizedPhoto
    }

    var body: some View {
        switch preferences.backgroundStyle {
        case .system:
            Color(uiColor: .secondarySystemBackground)

        case .solid:
            preferences.solidColor.color

        case .gradient:
            gradientBackground

        case .photo:
            if let image = loadsWidgetSizedPhoto
                ? SharedClockStorage.loadWidgetBackgroundImage()
                : SharedClockStorage.loadBackgroundImage()
            {
                Image(uiImage: image)
                    .resizable()
                    .preservingFullColorInWidgets()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .overlay {
                        Color.black.opacity(preferences.photoDimming)
                    }
            } else {
                LinearGradient(
                    colors: [
                        ClockPreferences.default.gradientStartColor.color,
                        ClockPreferences.default.gradientEndColor.color
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    @ViewBuilder
    private var gradientBackground: some View {
        let colors = [
            preferences.gradientStartColor.color,
            preferences.gradientEndColor.color
        ]

        switch preferences.gradientStyle {
        case .diagonalDown:
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        case .diagonalUp:
            LinearGradient(colors: colors, startPoint: .bottomLeading, endPoint: .topTrailing)
        case .horizontal:
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
        case .vertical:
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
        case .radial:
            GeometryReader { geometry in
                RadialGradient(
                    colors: colors,
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.72
                )
            }
        }
    }
}

private extension Image {
    @ViewBuilder
    func preservingFullColorInWidgets() -> some View {
        if #available(iOS 18.0, *) {
            widgetAccentedRenderingMode(.fullColor)
        } else {
            self
        }
    }
}

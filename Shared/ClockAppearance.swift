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
            LinearGradient(
                colors: [
                    preferences.gradientStartColor.color,
                    preferences.gradientEndColor.color
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

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

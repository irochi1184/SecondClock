import SwiftUI

struct ClockBackgroundView: View {
    let preferences: ClockPreferences

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
            if let image = SharedClockStorage.loadBackgroundImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
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

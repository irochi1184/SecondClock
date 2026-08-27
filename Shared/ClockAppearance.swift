import SwiftUI

struct ClockBackgroundView: View {
    let preferences: ClockPreferences
    let backgroundImage: UIImage?

    init(preferences: ClockPreferences, backgroundImage: UIImage? = nil) {
        self.preferences = preferences
        self.backgroundImage = backgroundImage
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
            if let image = backgroundImage ?? SharedClockStorage.loadBackgroundImage() {
                Image(uiImage: image)
                    .resizable()
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

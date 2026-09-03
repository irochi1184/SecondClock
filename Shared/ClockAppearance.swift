import SwiftUI
import WidgetKit

struct ClockBackgroundView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let preferences: ClockPreferences
    let loadsWidgetSizedPhoto: Bool
    let animatesBackground: Bool

    init(
        preferences: ClockPreferences,
        loadsWidgetSizedPhoto: Bool = false,
        animatesBackground: Bool = false
    ) {
        self.preferences = preferences
        self.loadsWidgetSizedPhoto = loadsWidgetSizedPhoto
        self.animatesBackground = animatesBackground
    }

    var body: some View {
        switch preferences.backgroundStyle {
        case .system:
            Color(uiColor: .secondarySystemBackground)

        case .solid:
            preferences.solidColor.color

        case .gradient:
            GradientClockBackground(
                preferences: preferences,
                isAnimated: animatesBackground && !reduceMotion
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

private struct GradientClockBackground: View {
    let preferences: ClockPreferences
    let isAnimated: Bool

    var body: some View {
        if preferences.backgroundMotion == .none {
            StaticClockGradient(preferences: preferences)
        } else if isAnimated {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                motionBackground(phase: phase(at: context.date))
            }
        } else {
            motionBackground(phase: 1.15)
        }
    }

    @ViewBuilder
    private func motionBackground(phase: Double) -> some View {
        switch preferences.backgroundMotion {
        case .none:
            StaticClockGradient(preferences: preferences)
        case .flowingGradient:
            FlowingGradientBackground(preferences: preferences, phase: phase)
        case .aurora:
            AuroraBackground(preferences: preferences, phase: phase)
        case .waves:
            WavesBackground(preferences: preferences, phase: phase)
        }
    }

    private func phase(at date: Date) -> Double {
        let baseRate: Double
        switch preferences.backgroundMotion {
        case .none: baseRate = 0
        case .flowingGradient: baseRate = 0.12
        case .aurora: baseRate = 0.085
        case .waves: baseRate = 0.18
        }

        return (date.timeIntervalSinceReferenceDate
            * baseRate
            * min(max(preferences.animationSpeed, 0.5), 2))
            .truncatingRemainder(dividingBy: .pi * 2)
    }
}

private struct StaticClockGradient: View {
    let preferences: ClockPreferences

    private var colors: [Color] {
        [
            preferences.gradientStartColor.color,
            preferences.gradientEndColor.color
        ]
    }

    @ViewBuilder
    var body: some View {
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

private struct FlowingGradientBackground: View {
    let preferences: ClockPreferences
    let phase: Double

    var body: some View {
        GeometryReader { geometry in
            let intensity = min(max(preferences.animationIntensity, 0.2), 1)
            let longSide = max(geometry.size.width, geometry.size.height)

            ZStack {
                StaticClockGradient(preferences: preferences)

                RadialGradient(
                    colors: [
                        preferences.gradientStartColor.color.opacity(0.9),
                        preferences.gradientEndColor.color.opacity(0)
                    ],
                    center: UnitPoint(
                        x: 0.5 + sin(phase) * 0.32,
                        y: 0.5 + cos(phase * 0.82) * 0.3
                    ),
                    startRadius: 0,
                    endRadius: longSide * 0.72
                )
                .scaleEffect(1.25)
                .opacity(0.18 + intensity * 0.5)
                .blendMode(.screen)

                LinearGradient(
                    colors: [
                        .clear,
                        preferences.gradientEndColor.color.opacity(0.7),
                        preferences.gradientStartColor.color.opacity(0.65),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: longSide * 1.5, height: longSide * 0.55)
                .rotationEffect(.radians(phase * 0.42 + 0.3))
                .offset(
                    x: sin(phase * 0.7) * geometry.size.width * 0.2,
                    y: cos(phase * 0.58) * geometry.size.height * 0.16
                )
                .blur(radius: 28)
                .opacity(0.12 + intensity * 0.38)
                .blendMode(.plusLighter)
            }
            .clipped()
        }
    }
}

private struct AuroraBackground: View {
    let preferences: ClockPreferences
    let phase: Double

    var body: some View {
        GeometryReader { geometry in
            let intensity = min(max(preferences.animationIntensity, 0.2), 1)

            ZStack {
                LinearGradient(
                    colors: [
                        preferences.gradientStartColor.color,
                        Color.black.opacity(0.88),
                        preferences.gradientEndColor.color.opacity(0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                AuroraRibbonShape(
                    phase: phase,
                    baseline: 0.36,
                    amplitude: 0.12 + intensity * 0.08,
                    thickness: 0.2
                )
                .fill(
                    LinearGradient(
                        colors: [
                            preferences.gradientStartColor.color.opacity(0.08),
                            preferences.gradientEndColor.color.opacity(0.82),
                            Color.white.opacity(0.18),
                            preferences.gradientStartColor.color.opacity(0.05)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .blur(radius: 18 + intensity * 16)
                .opacity(0.4 + intensity * 0.48)

                AuroraRibbonShape(
                    phase: -phase * 0.76 + 2.1,
                    baseline: 0.58,
                    amplitude: 0.1 + intensity * 0.06,
                    thickness: 0.16
                )
                .fill(
                    LinearGradient(
                        colors: [
                            preferences.gradientEndColor.color.opacity(0),
                            preferences.gradientStartColor.color.opacity(0.72),
                            preferences.gradientEndColor.color.opacity(0.14)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .blur(radius: 22 + intensity * 18)
                .opacity(0.3 + intensity * 0.45)
                .blendMode(.screen)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }
}

private struct WavesBackground: View {
    let preferences: ClockPreferences
    let phase: Double

    var body: some View {
        GeometryReader { geometry in
            let intensity = min(max(preferences.animationIntensity, 0.2), 1)

            ZStack {
                LinearGradient(
                    colors: [
                        preferences.gradientStartColor.color,
                        preferences.gradientEndColor.color.opacity(0.8),
                        Color.black.opacity(0.76)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                WaveShape(
                    phase: phase,
                    frequency: 1.35,
                    amplitude: 0.045 + intensity * 0.055,
                    baseline: 0.5
                )
                .fill(preferences.gradientEndColor.color.opacity(0.28 + intensity * 0.28))
                .blur(radius: 6)

                WaveShape(
                    phase: -phase * 0.72 + 1.7,
                    frequency: 1.8,
                    amplitude: 0.035 + intensity * 0.045,
                    baseline: 0.64
                )
                .fill(preferences.gradientStartColor.color.opacity(0.34 + intensity * 0.32))
                .blur(radius: 10)
                .blendMode(.screen)

                WaveShape(
                    phase: phase * 0.48 + 3.2,
                    frequency: 1.1,
                    amplitude: 0.03 + intensity * 0.035,
                    baseline: 0.76
                )
                .fill(Color.white.opacity(0.04 + intensity * 0.1))
                .blur(radius: 14)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }
}

private struct AuroraRibbonShape: Shape {
    let phase: Double
    let baseline: Double
    let amplitude: Double
    let thickness: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = 64

        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            let x = rect.width * progress
            let wave = sin(progress * .pi * 2 * 1.25 + phase)
                + sin(progress * .pi * 2 * 0.54 - phase * 0.65) * 0.45
            let y = rect.height * (baseline + wave * amplitude)

            if step == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        for step in stride(from: steps, through: 0, by: -1) {
            let progress = Double(step) / Double(steps)
            let x = rect.width * progress
            let wave = sin(progress * .pi * 2 * 1.25 + phase + 0.45)
                + sin(progress * .pi * 2 * 0.54 - phase * 0.65) * 0.35
            let y = rect.height * (baseline + thickness + wave * amplitude * 0.66)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.closeSubpath()
        return path
    }
}

private struct WaveShape: Shape {
    let phase: Double
    let frequency: Double
    let amplitude: Double
    let baseline: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = 72

        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            let x = rect.width * progress
            let wave = sin(progress * .pi * 2 * frequency + phase)
                + sin(progress * .pi * 2 * frequency * 0.47 - phase * 0.62) * 0.35
            let y = rect.height * (baseline + wave * amplitude)

            if step == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
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

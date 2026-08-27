import SwiftUI
import UIKit
import WidgetKit

struct ClockTimelineEntry: TimelineEntry {
    let date: Date
    let startOfDay: Date
    let preferences: ClockPreferences
    let backgroundImage: UIImage?

    init(
        date: Date,
        startOfDay: Date,
        preferences: ClockPreferences,
        backgroundImage: UIImage? = nil
    ) {
        self.date = date
        self.startOfDay = startOfDay
        self.preferences = preferences
        self.backgroundImage = backgroundImage
    }
}

struct SecondClockTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClockTimelineEntry {
        let now = Date()
        return ClockTimelineEntry(
            date: now,
            startOfDay: Calendar.current.startOfDay(for: now),
            preferences: .default
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (ClockTimelineEntry) -> Void
    ) {
        let now = Date()
        let preferences = SharedClockStorage.loadPreferences()
        completion(
            ClockTimelineEntry(
                date: now,
                startOfDay: Calendar.current.startOfDay(for: now),
                preferences: preferences,
                backgroundImage: backgroundImage(for: preferences)
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<ClockTimelineEntry>) -> Void
    ) {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let preferences = SharedClockStorage.loadPreferences()
        let backgroundImage = backgroundImage(for: preferences)

        var entries = [
            ClockTimelineEntry(
                date: now,
                startOfDay: today,
                preferences: preferences,
                backgroundImage: backgroundImage
            )
        ]

        for dayOffset in 1...7 {
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }
            entries.append(
                ClockTimelineEntry(
                    date: dayStart,
                    startOfDay: dayStart,
                    preferences: preferences,
                    backgroundImage: backgroundImage
                )
            )
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func backgroundImage(for preferences: ClockPreferences) -> UIImage? {
        guard preferences.backgroundStyle == .photo else { return nil }
        return SharedClockStorage.loadBackgroundImage()
    }
}

struct SecondClockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ClockTimelineEntry

    private var isAccessory: Bool {
        family == .accessoryRectangular
    }

    private var timeFontSize: CGFloat {
        switch family {
        case .systemMedium: 54
        case .accessoryRectangular: 27
        default: 38
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: isAccessory ? 1 : 6) {
            if entry.preferences.showDate {
                Text(
                    entry.date,
                    format: isAccessory
                        ? .dateTime.month(.abbreviated).day().weekday(.abbreviated)
                        : .dateTime.month(.wide).day().weekday(.wide)
                )
                .font(
                    .system(
                        size: isAccessory ? 11 : 13,
                        weight: .medium,
                        design: entry.preferences.fontDesign.swiftUIFontDesign
                    )
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(1)
            }

            Text(entry.startOfDay, style: .timer)
                .font(
                    .system(
                        size: timeFontSize,
                        weight: entry.preferences.fontWeight.swiftUIFontWeight,
                        design: entry.preferences.fontDesign.swiftUIFontDesign
                    )
                )
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .minimumScaleFactor(0.45)
                .lineLimit(1)
        }
        .foregroundStyle(isAccessory ? Color.primary : entry.preferences.textColor.color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(isAccessory ? 0 : 12)
        .shadow(
            color: isAccessory ? .clear : .black.opacity(0.22),
            radius: 6,
            y: 2
        )
        .containerBackground(for: .widget) {
            if isAccessory {
                Color.clear
            } else {
                ClockBackgroundView(
                    preferences: entry.preferences,
                    backgroundImage: entry.backgroundImage
                )
            }
        }
    }
}

struct SecondClockWidget: Widget {
    let kind = SharedClockStorage.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SecondClockTimelineProvider()) { entry in
            SecondClockWidgetView(entry: entry)
        }
        .configurationDisplayName("秒まで見える時計")
        .description("現在時刻を24時間形式で秒まで表示します。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
        .containerBackgroundRemovable(false)
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    SecondClockWidget()
} timeline: {
    let now = Date()
    ClockTimelineEntry(
        date: now,
        startOfDay: Calendar.current.startOfDay(for: now),
        preferences: .default
    )
}

#Preview(as: .accessoryRectangular) {
    SecondClockWidget()
} timeline: {
    let now = Date()
    ClockTimelineEntry(
        date: now,
        startOfDay: Calendar.current.startOfDay(for: now),
        preferences: .default
    )
}

import SwiftUI
import WidgetKit

struct ClockTimelineEntry: TimelineEntry {
    let date: Date
    let startOfDay: Date
    let preferences: ClockPreferences
    let backgroundImageRevision: Date?
    let presetName: String
    let presetCount: Int
    let followsActivePreset: Bool
    let scheduleIsActive: Bool

    init(
        date: Date,
        startOfDay: Date,
        preferences: ClockPreferences,
        backgroundImageRevision: Date? = nil,
        presetName: String = "プリセット",
        presetCount: Int = 1,
        followsActivePreset: Bool = true,
        scheduleIsActive: Bool = false
    ) {
        self.date = date
        self.startOfDay = startOfDay
        self.preferences = preferences
        self.backgroundImageRevision = backgroundImageRevision
        self.presetName = presetName
        self.presetCount = presetCount
        self.followsActivePreset = followsActivePreset
        self.scheduleIsActive = scheduleIsActive
    }
}

struct SecondClockTimelineProvider: AppIntentTimelineProvider {
    typealias Intent = ClockWidgetConfigurationIntent

    func placeholder(in context: Context) -> ClockTimelineEntry {
        let now = Date()
        return ClockTimelineEntry(
            date: now,
            startOfDay: Calendar.current.startOfDay(for: now),
            preferences: .default
        )
    }

    func snapshot(
        for configuration: ClockWidgetConfigurationIntent,
        in context: Context
    ) async -> ClockTimelineEntry {
        let now = Date()
        return makeEntry(at: now, configuration: configuration)
    }

    func timeline(
        for configuration: ClockWidgetConfigurationIntent,
        in context: Context
    ) async -> Timeline<ClockTimelineEntry> {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let entries = timelineDates(from: now, calendar: calendar).map {
            makeEntry(at: $0, configuration: configuration)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func makeEntry(
        at date: Date,
        configuration: ClockWidgetConfigurationIntent
    ) -> ClockTimelineEntry {
        let calendar = Calendar.autoupdatingCurrent
        let collection = SharedClockStorage.loadPresetCollection()
        let fixedPresetID = SharedClockStorage.isProEntitlementCached
            ? configuration.preset.flatMap { UUID(uuidString: $0.id) }
            : nil
        let preset = SharedClockStorage.resolvedPreset(at: date, presetID: fixedPresetID)
        let preferences = preset.preferences.applying(
            accessLevel: ClockAccessLevel(
                isProUnlocked: SharedClockStorage.isProEntitlementCached
            )
        )
        let schedule = SharedClockStorage.loadPresetSchedule()

        return ClockTimelineEntry(
            date: date,
            startOfDay: calendar.startOfDay(for: date),
            preferences: preferences,
            backgroundImageRevision: backgroundImageRevision(for: preferences),
            presetName: preset.name,
            presetCount: collection.presets.count,
            followsActivePreset: fixedPresetID == nil,
            scheduleIsActive: fixedPresetID == nil
                && SharedClockStorage.isProEntitlementCached
                && schedule.isEnabled
        )
    }

    private func timelineDates(from now: Date, calendar: Calendar) -> [Date] {
        let collection = SharedClockStorage.loadPresetCollection()
        let schedule = SharedClockStorage.loadPresetSchedule()
        var transitionMinutes: Set<Int> = [0]

        if schedule.isEnabled && SharedClockStorage.isProEntitlementCached {
            transitionMinutes.insert(schedule.dayStartMinutes)
            transitionMinutes.insert(schedule.nightStartMinutes)
        }

        for preset in collection.presets where preset.preferences.nightMode == .scheduled {
            transitionMinutes.insert(preset.preferences.nightStartMinutes)
            transitionMinutes.insert(preset.preferences.nightEndMinutes)
        }

        let today = calendar.startOfDay(for: now)
        var dates: Set<Date> = [now]
        for dayOffset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }
            for minutes in transitionMinutes {
                guard let transition = calendar.date(
                    byAdding: .minute,
                    value: min(max(minutes, 0), 1_439),
                    to: day
                ), transition > now
                else {
                    continue
                }
                dates.insert(transition)
            }
        }
        return dates.sorted()
    }

    private func backgroundImageRevision(for preferences: ClockPreferences) -> Date? {
        guard preferences.backgroundStyle == .photo else { return nil }
        return SharedClockStorage.backgroundImageModificationDate
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
        .opacity(
            !isAccessory && entry.preferences.isNightModeActive(at: entry.date)
                ? min(max(entry.preferences.nightTextIntensity, 0.2), 1)
                : 1
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(isAccessory ? 0 : 12)
        .shadow(
            color: isAccessory ? .clear : .black.opacity(0.22),
            radius: 6,
            y: 2
        )
        .overlay(alignment: .bottom) {
            if entry.followsActivePreset
                && !entry.scheduleIsActive
                && entry.presetCount > 1
            {
                presetControls
            }
        }
        .containerBackground(for: .widget) {
            if isAccessory {
                Color.clear
            } else if entry.preferences.isNightModeActive(at: entry.date) {
                Color.black
            } else {
                ClockBackgroundView(
                    preferences: entry.preferences,
                    loadsWidgetSizedPhoto: true,
                    animatesBackground: false
                )
                .id(entry.backgroundImageRevision)
            }
        }
        .contentTransition(.interpolate)
        .animation(.easeInOut(duration: 1.2), value: entry.preferences)
    }

    private var presetControls: some View {
        HStack {
            Button(intent: SwitchClockPresetIntent(direction: .previous)) {
                Image(systemName: "chevron.left")
                    .frame(width: isAccessory ? 20 : 28, height: isAccessory ? 20 : 28)
            }

            if !isAccessory {
                Spacer()
                Text(entry.presetName)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                Spacer()
            } else {
                Spacer(minLength: 22)
            }

            Button(intent: SwitchClockPresetIntent(direction: .next)) {
                Image(systemName: "chevron.right")
                    .frame(width: isAccessory ? 20 : 28, height: isAccessory ? 20 : 28)
            }
        }
        .buttonStyle(.plain)
        .font(.caption.bold())
        .padding(.horizontal, isAccessory ? 0 : 4)
    }
}

struct SecondClockWidget: Widget {
    let kind = SharedClockStorage.widgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ClockWidgetConfigurationIntent.self,
            provider: SecondClockTimelineProvider()
        ) { entry in
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

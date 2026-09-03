import PhotosUI
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var settingsStore: ClockSettingsStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var showsSettings = false
    @State private var presetFeedbackName: String?
    @State private var presetFeedbackToken = UUID()
    @State private var currentDate = Date()

    private var effectivePreferences: ClockPreferences {
        settingsStore.effectivePreferences(
            isProUnlocked: purchaseManager.isProUnlocked,
            at: currentDate
        )
    }

    private var isNightModeActive: Bool {
        effectivePreferences.isNightModeActive(at: currentDate)
    }

    init(initiallyShowsSettings: Bool = false) {
        _showsSettings = State(initialValue: initiallyShowsSettings)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Group {
                    if isNightModeActive {
                        Color.black
                    } else {
                        ClockBackgroundView(
                            preferences: effectivePreferences,
                            animatesBackground: true
                        )
                    }
                }
                    .id(settingsStore.backgroundImageRevision)
                    .id(
                        settingsStore.effectivePresetID(
                            isProUnlocked: purchaseManager.isProUnlocked,
                            at: currentDate
                        )
                    )
                    .transition(.opacity)
                    .ignoresSafeArea()

                FullScreenClockView(
                    preferences: effectivePreferences,
                    isNightModeActive: isNightModeActive
                )
                    .id(
                        settingsStore.effectivePresetID(
                            isProUnlocked: purchaseManager.isProUnlocked,
                            at: currentDate
                        )
                    )
                    .scaleEffect(
                        showsSettings && geometry.size.width > geometry.size.height
                            ? 0.8
                            : 1
                    )
                    .offset(y: showsSettings ? -geometry.size.height * 0.24 : 0)

                VStack {
                    HStack {
                        Spacer()

                        Button {
                            showsSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 21, weight: .semibold))
                                .frame(width: 48, height: 48)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay {
                                    Circle()
                                        .stroke(.white.opacity(0.18), lineWidth: 1)
                                }
                                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                        .accessibilityLabel("時計の設定を開く")
                        .accessibilityHint("時計を見ながら表示サイズや背景を変更できます")
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if settingsStore.presets.count > 1 && !showsSettings {
                    presetIndicator
                }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(presetSwipeGesture)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.22), value: settingsStore.activePresetID)
        .animation(.easeInOut(duration: 0.4), value: displayedPresetID)
        .animation(.easeInOut(duration: 0.4), value: isNightModeActive)
        .animation(.easeInOut(duration: 0.28), value: showsSettings)
        .statusBarHidden(!showsSettings)
        .persistentSystemOverlays(showsSettings ? .visible : .hidden)
        .sheet(isPresented: $showsSettings) {
            ClockSettingsView()
                .environmentObject(settingsStore)
                .environmentObject(purchaseManager)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(
                    .enabled(upThrough: .fraction(0.5))
                )
                .presentationContentInteraction(.scrolls)
                .presentationCornerRadius(28)
        }
        .onChange(of: scenePhase) { _, newPhase in
            updateIdleTimer(for: newPhase)
            guard newPhase == .active else { return }
            settingsStore.reloadFromSharedStorage()
            currentDate = .now
            Task { await purchaseManager.start() }
        }
        .onChange(of: effectivePreferences.keepsScreenAwake) { _, _ in
            updateIdleTimer(for: scenePhase)
        }
        .onAppear {
            updateIdleTimer(for: scenePhase)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .task {
            while !Task.isCancelled {
                currentDate = .now
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    private var presetIndicator: some View {
        VStack(spacing: 8) {
            if let presetFeedbackName {
                Text(presetFeedbackName)
                    .font(.caption.weight(.semibold))
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }

            Group {
                if settingsStore.presets.count <= 8 {
                    HStack(spacing: 7) {
                        ForEach(settingsStore.presets) { preset in
                            Circle()
                                .fill(
                                    preset.id == displayedPresetID
                                        ? Color.primary
                                        : Color.primary.opacity(0.3)
                                )
                                .frame(width: 7, height: 7)
                        }
                    }
                } else {
                    Text("\(activePresetIndex + 1) / \(settingsStore.presets.count)")
                        .font(.caption2.monospacedDigit().weight(.semibold))
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 26)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .foregroundStyle(effectivePreferences.textColor.color)
        .shadow(color: .black.opacity(0.22), radius: 6, y: 2)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 18)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(displayedPresetName)、\(activePresetIndex + 1)個目、全\(settingsStore.presets.count)個"
        )
    }

    private var activePresetIndex: Int {
        return settingsStore.presets.firstIndex(where: {
            $0.id == displayedPresetID
        }) ?? 0
    }

    private var displayedPresetID: UUID {
        settingsStore.effectivePresetID(
            isProUnlocked: purchaseManager.isProUnlocked,
            at: currentDate
        )
    }

    private var displayedPresetName: String {
        settingsStore.effectivePresetName(
            isProUnlocked: purchaseManager.isProUnlocked,
            at: currentDate
        )
    }

    private var presetSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 35)
            .onEnded { value in
                guard !showsSettings,
                      !(purchaseManager.isProUnlocked && settingsStore.presetSchedule.isEnabled),
                      abs(value.translation.width) > abs(value.translation.height),
                      abs(value.translation.width) >= 60
                else {
                    return
                }

                let didChange = settingsStore.selectAdjacentPreset(
                    forward: value.translation.width < 0
                )
                guard didChange else { return }
                showPresetFeedback()
            }
    }

    private func showPresetFeedback() {
        let token = UUID()
        presetFeedbackToken = token

        withAnimation(.easeOut(duration: 0.18)) {
            presetFeedbackName = settingsStore.activePresetName
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard presetFeedbackToken == token else { return }
            withAnimation(.easeIn(duration: 0.18)) {
                presetFeedbackName = nil
            }
        }
    }

    private func updateIdleTimer(for phase: ScenePhase) {
        UIApplication.shared.isIdleTimerDisabled = phase == .active
            && effectivePreferences.keepsScreenAwake
    }
}

private struct FullScreenClockView: View {
    let preferences: ClockPreferences
    let isNightModeActive: Bool

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ClockLayoutContent(
                    preferences: preferences,
                    date: context.date,
                    size: geometry.size
                )
                .foregroundStyle(preferences.textColor.color)
                .opacity(
                    isNightModeActive
                        ? min(max(preferences.nightTextIntensity, 0.2), 1)
                        : 1
                )
                .multilineTextAlignment(.center)
                .shadow(
                    color: isNightModeActive ? .clear : .black.opacity(0.3),
                    radius: 9,
                    y: 3
                )
                .offset(burnInOffset(at: context.date))
                .animation(.easeInOut(duration: 1.2), value: preferences.layoutStyle)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func burnInOffset(at date: Date) -> CGSize {
        guard isNightModeActive && preferences.burnInProtection else { return .zero }
        let minute = floor(date.timeIntervalSinceReferenceDate / 60)
        return CGSize(
            width: sin(minute * 2.399) * 10,
            height: cos(minute * 1.733) * 8
        )
    }
}

private struct ClockLayoutContent: View {
    let preferences: ClockPreferences
    let date: Date
    let size: CGSize

    private var baseSize: CGFloat {
        min(
            size.width / 5.9,
            size.height * (preferences.showDate ? 0.34 : 0.44)
        ) * preferences.displaySize.scale
    }

    private var timeFontSize: CGFloat { max(38, baseSize) }
    private var dateFontSize: CGFloat { max(15, timeFontSize * 0.2) }

    var body: some View {
        switch preferences.layoutStyle {
        case .classic:
            classicLayout
        case .secondsFocus:
            secondsFocusLayout
        case .flip:
            flipLayout
        case .secondsRing:
            secondsRingLayout
        }
    }

    private var classicLayout: some View {
        VStack(spacing: max(8, timeFontSize * 0.1)) {
            dateLabel
            Text(
                date,
                format: .dateTime
                    .hour(.twoDigits(amPM: .omitted))
                    .minute(.twoDigits)
                    .second(.twoDigits)
            )
            .font(clockFont(size: timeFontSize))
            .monospacedDigit()
            .allowsTightening(true)
            .minimumScaleFactor(0.38)
            .lineLimit(1)
        }
    }

    private var secondsFocusLayout: some View {
        let components = Calendar.autoupdatingCurrent.dateComponents(
            [.hour, .minute, .second],
            from: date
        )
        let hoursMinutes = String(
            format: "%02d:%02d",
            components.hour ?? 0,
            components.minute ?? 0
        )
        let seconds = String(format: "%02d", components.second ?? 0)

        return VStack(spacing: max(6, timeFontSize * 0.06)) {
            dateLabel
            HStack(alignment: .lastTextBaseline, spacing: max(10, timeFontSize * 0.12)) {
                Text(hoursMinutes)
                    .font(clockFont(size: timeFontSize * 0.86))
                Text(seconds)
                    .font(clockFont(size: timeFontSize * 1.28))
                    .padding(.horizontal, timeFontSize * 0.15)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
            .monospacedDigit()
            .minimumScaleFactor(0.35)
            .lineLimit(1)
        }
    }

    private var flipLayout: some View {
        let components = Calendar.autoupdatingCurrent.dateComponents(
            [.hour, .minute, .second],
            from: date
        )

        return VStack(spacing: max(10, timeFontSize * 0.12)) {
            dateLabel
            HStack(spacing: max(6, timeFontSize * 0.08)) {
                FlipClockUnit(value: components.hour ?? 0, font: clockFont(size: timeFontSize * 0.72))
                Text(":").font(clockFont(size: timeFontSize * 0.62))
                FlipClockUnit(value: components.minute ?? 0, font: clockFont(size: timeFontSize * 0.72))
                Text(":").font(clockFont(size: timeFontSize * 0.62))
                FlipClockUnit(value: components.second ?? 0, font: clockFont(size: timeFontSize * 0.72))
            }
            .minimumScaleFactor(0.42)
            .lineLimit(1)
        }
    }

    private var secondsRingLayout: some View {
        let second = Calendar.autoupdatingCurrent.component(.second, from: date)
        let diameter = min(size.width * 0.72, size.height * (preferences.showDate ? 0.68 : 0.8))

        return VStack(spacing: 8) {
            dateLabel
            ZStack {
                Circle()
                    .stroke(.primary.opacity(0.16), lineWidth: max(7, diameter * 0.035))
                Circle()
                    .trim(from: 0, to: CGFloat(second + 1) / 60)
                    .stroke(
                        preferences.textColor.color,
                        style: StrokeStyle(
                            lineWidth: max(7, diameter * 0.035),
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                Text(
                    date,
                    format: .dateTime
                        .hour(.twoDigits(amPM: .omitted))
                        .minute(.twoDigits)
                        .second(.twoDigits)
                )
                .font(clockFont(size: max(28, diameter * 0.18)))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(diameter * 0.12)
            }
            .frame(width: diameter, height: diameter)
        }
    }

    @ViewBuilder
    private var dateLabel: some View {
        if preferences.showDate {
            Text(
                date,
                format: .dateTime
                    .year()
                    .month(.wide)
                    .day()
                    .weekday(.wide)
            )
            .font(
                .system(
                    size: dateFontSize,
                    weight: .medium,
                    design: preferences.fontDesign.swiftUIFontDesign
                )
            )
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
    }

    private func clockFont(size: CGFloat) -> Font {
        .system(
            size: size,
            weight: preferences.fontWeight.swiftUIFontWeight,
            design: preferences.fontDesign.swiftUIFontDesign
        )
    }
}

private struct FlipClockUnit: View {
    let value: Int
    let font: Font

    var body: some View {
        Text(String(format: "%02d", value))
            .font(font)
            .monospacedDigit()
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.black.opacity(0.46), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                Rectangle()
                    .fill(.white.opacity(0.14))
                    .frame(height: 1)
            }
            .contentTransition(.numericText())
    }
}

struct ClockSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: ClockSettingsStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var showsResetConfirmation = false
    @State private var showsPresetDeleteConfirmation = false
    @State private var showsPaywall = false

    private var effectivePreferences: ClockPreferences {
        settingsStore.preferences.applying(
            accessLevel: ClockAccessLevel(
                isProUnlocked: purchaseManager.isProUnlocked
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if shouldShowAppGroupWarning {
                        AppGroupWarning()
                    }

                    displaySection
                    clockDesignSection
                    typographySection
                    backgroundSection
                    deviceSection
                    presetSection
                    scheduleSection
                    proStatusCard
                    informationSection
                    resetSection
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("時計の設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(
                "画像を設定できませんでした",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("閉じる", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "不明なエラーです。")
            }
            .confirmationDialog(
                "設定を初期状態に戻しますか？",
                isPresented: $showsResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("初期状態に戻す", role: .destructive) {
                    settingsStore.restoreDefaults()
                }
                Button("キャンセル", role: .cancel) {}
            }
            .confirmationDialog(
                "「\(settingsStore.activePresetName)」を削除しますか？",
                isPresented: $showsPresetDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("プリセットを削除", role: .destructive) {
                    settingsStore.deleteActivePreset()
                }
                Button("キャンセル", role: .cancel) {}
            }
            .sheet(isPresented: $showsPaywall) {
                ProPaywallView()
                    .environmentObject(purchaseManager)
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var shouldShowAppGroupWarning: Bool {
        #if DEBUG && targetEnvironment(simulator)
        if ProcessInfo.processInfo.environment["SECOND_CLOCK_SCREENSHOT_MODE"] != nil {
            return false
        }
        #endif
        return !settingsStore.isAppGroupAvailable
    }

    private var displaySection: some View {
        SettingsCard(title: "表示") {
            Picker("時計の大きさ", selection: $settingsStore.preferences.displaySize) {
                ForEach(ClockDisplaySize.allCases) { size in
                    Text(size.title).tag(size)
                }
            }
            .pickerStyle(.segmented)

            Toggle("日付を表示", isOn: $settingsStore.preferences.showDate)

            Text("時刻は24時間形式で、秒まで表示します。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var clockDesignSection: some View {
        SettingsCard(title: "時計デザイン") {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach(ClockLayoutStyle.allCases) { style in
                    ClockOptionButton(
                        title: style.title,
                        isSelected: effectivePreferences.layoutStyle == style,
                        isLocked: style.requiresPro && !purchaseManager.isProUnlocked
                    ) {
                        if style.requiresPro && !purchaseManager.isProUnlocked {
                            showsPaywall = true
                        } else {
                            settingsStore.preferences.layoutStyle = style
                        }
                    }
                }
            }

            Text("クラシックと秒を強調するデザインは無料で利用できます。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var presetSection: some View {
        SettingsCard(title: "プリセット") {
            Picker("使用中", selection: activePresetBinding) {
                ForEach(settingsStore.presets) { preset in
                    Text(preset.name).tag(preset.id)
                }
            }
            .pickerStyle(.menu)

            Button {
                if !settingsStore.addPreset(
                    isProUnlocked: purchaseManager.isProUnlocked
                ) {
                    showsPaywall = true
                }
            } label: {
                Label("現在の設定を複製して追加", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if settingsStore.presets.count > 1 {
                Button(role: .destructive) {
                    showsPresetDeleteConfirmation = true
                } label: {
                    Label("使用中のプリセットを削除", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Text(presetLimitDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("時計画面を左右にスワイプして切り替えられます。選択内容はウィジェットにも反映されます。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var deviceSection: some View {
        SettingsCard(title: "置き時計モード") {
            Toggle(
                "表示中は画面をスリープさせない",
                isOn: $settingsStore.preferences.keepsScreenAwake
            )

            Divider()

            Picker("OLEDナイトモード", selection: nightModeBinding) {
                ForEach(ClockNightMode.allCases) { mode in
                    Text(
                        mode.requiresPro && !purchaseManager.isProUnlocked
                            ? "\(mode.title)（Pro）"
                            : mode.title
                    )
                    .tag(mode)
                }
            }
            .pickerStyle(.menu)

            if settingsStore.preferences.nightMode == .scheduled
                && purchaseManager.isProUnlocked
            {
                DatePicker(
                    "開始",
                    selection: timeBinding(for: \ClockPreferences.nightStartMinutes),
                    displayedComponents: .hourAndMinute
                )
                DatePicker(
                    "終了",
                    selection: timeBinding(for: \ClockPreferences.nightEndMinutes),
                    displayedComponents: .hourAndMinute
                )
            }

            if effectivePreferences.nightMode != .off {
                VStack(alignment: .leading, spacing: 8) {
                    Text("文字の明るさ")
                        .font(.subheadline)
                    Slider(
                        value: $settingsStore.preferences.nightTextIntensity,
                        in: 0.2...1,
                        step: 0.05
                    )
                }

                Toggle(
                    "焼き付き対策で時計位置を少し動かす",
                    isOn: $settingsStore.preferences.burnInProtection
                )
            }

            Text("ナイトモードでは背景を完全な黒にし、文字を暗く表示します。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var scheduleSection: some View {
        SettingsCard(title: "プリセット自動切替") {
            Toggle("時刻に合わせて自動切替", isOn: scheduleEnabledBinding)

            if purchaseManager.isProUnlocked && settingsStore.presetSchedule.isEnabled {
                Picker("昼のプリセット", selection: schedulePresetBinding(isDay: true)) {
                    ForEach(settingsStore.presets) { preset in
                        Text(preset.name).tag(Optional(preset.id))
                    }
                }
                .pickerStyle(.menu)

                DatePicker(
                    "昼に切り替える時刻",
                    selection: scheduleTimeBinding(isDay: true),
                    displayedComponents: .hourAndMinute
                )

                Picker("夜のプリセット", selection: schedulePresetBinding(isDay: false)) {
                    ForEach(settingsStore.presets) { preset in
                        Text(preset.name).tag(Optional(preset.id))
                    }
                }
                .pickerStyle(.menu)

                DatePicker(
                    "夜に切り替える時刻",
                    selection: scheduleTimeBinding(isDay: false),
                    displayedComponents: .hourAndMinute
                )

                Text("自動切替中は、全画面とウィジェットのスワイプ・切替ボタンよりもスケジュールを優先します。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if !purchaseManager.isProUnlocked {
                Text("時間帯に合わせた自動切替はPro版で利用できます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var activePresetBinding: Binding<UUID> {
        Binding(
            get: { settingsStore.activePresetID },
            set: { settingsStore.selectPreset(id: $0) }
        )
    }

    private var presetLimitDescription: String {
        if purchaseManager.isProUnlocked {
            "Pro版：プリセット数は無制限（現在\(settingsStore.presets.count)件）"
        } else {
            "無料版：最大\(ClockPresetAccessPolicy.freeLimit)件（現在\(settingsStore.presets.count)件）"
        }
    }

    private var typographySection: some View {
        SettingsCard(title: "時計の種類") {
            Text("書体")
                .font(.subheadline)

            HStack(spacing: 8) {
                ForEach(ClockFontDesign.allCases) { design in
                    ClockOptionButton(
                        title: design.title,
                        isSelected: effectivePreferences.fontDesign == design,
                        isLocked: design.requiresPro && !purchaseManager.isProUnlocked
                    ) {
                        selectFontDesign(design)
                    }
                }
            }

            Text("太さ")
                .font(.subheadline)

            HStack(spacing: 8) {
                ForEach(ClockFontWeight.allCases) { weight in
                    ClockOptionButton(
                        title: weight.title,
                        isSelected: effectivePreferences.fontWeight == weight,
                        isLocked: weight.requiresPro && !purchaseManager.isProUnlocked
                    ) {
                        selectFontWeight(weight)
                    }
                }
            }

            ColorPicker(
                "文字色",
                selection: colorBinding(for: \ClockPreferences.textColor),
                supportsOpacity: false
            )
        }
    }

    @ViewBuilder
    private var backgroundSection: some View {
        SettingsCard(title: "背景") {
            themePresets

            Picker("種類", selection: backgroundStyleBinding) {
                ForEach(ClockBackgroundStyle.allCases) { style in
                    Text(
                        style.requiresPro && !purchaseManager.isProUnlocked
                            ? "\(style.title)（Pro）"
                            : style.title
                    )
                    .tag(style)
                }
            }
            .pickerStyle(.menu)

            switch effectivePreferences.backgroundStyle {
            case .system:
                Text("画面の外観に合わせて、iOSが背景色を調整します。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

            case .solid:
                ColorPicker(
                    "背景色",
                    selection: colorBinding(for: \ClockPreferences.solidColor),
                    supportsOpacity: false
                )

            case .gradient:
                if purchaseManager.isProUnlocked {
                    Picker(
                        "グラデーションの種類",
                        selection: $settingsStore.preferences.gradientStyle
                    ) {
                        ForEach(ClockGradientStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                } else {
                    LockedSettingButton(title: "グラデーションの種類を変更") {
                        showsPaywall = true
                    }

                    Text("無料版では「左上 → 右下」を使用します。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ColorPicker(
                    "開始色",
                    selection: colorBinding(for: \ClockPreferences.gradientStartColor),
                    supportsOpacity: false
                )
                ColorPicker(
                    "終了色",
                    selection: colorBinding(for: \ClockPreferences.gradientEndColor),
                    supportsOpacity: false
                )

                Divider()

                if purchaseManager.isProUnlocked {
                    Picker(
                        "背景アニメーション",
                        selection: $settingsStore.preferences.backgroundMotion
                    ) {
                        ForEach(ClockBackgroundMotion.allCases) { motion in
                            Text(motion.title).tag(motion)
                        }
                    }
                    .pickerStyle(.menu)

                    if settingsStore.preferences.backgroundMotion != .none {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("動きの速さ")
                                Spacer()
                                Text(
                                    settingsStore.preferences.animationSpeed,
                                    format: .number.precision(.fractionLength(1))
                                )
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            }
                            .font(.subheadline)

                            Slider(
                                value: $settingsStore.preferences.animationSpeed,
                                in: 0.5...2,
                                step: 0.1
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("動きの強さ")
                                Spacer()
                                Text(
                                    settingsStore.preferences.animationIntensity,
                                    format: .percent.precision(.fractionLength(0))
                                )
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            }
                            .font(.subheadline)

                            Slider(
                                value: $settingsStore.preferences.animationIntensity,
                                in: 0.2...1,
                                step: 0.05
                            )
                        }

                        Text("アプリでは常時動き、ウィジェットには同じデザインの静止状態を表示します。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    LockedSettingButton(title: "背景アニメーションを設定") {
                        showsPaywall = true
                    }

                    Text("背景アニメーションはPro版で利用できます。ウィジェットは静止表示です。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

            case .photo:
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("背景写真を選択", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .onChange(of: selectedPhoto) { _, newItem in
                    guard let newItem else { return }
                    Task { await importPhoto(from: newItem) }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("写真の暗さ")
                        .font(.subheadline)
                    Slider(value: $settingsStore.preferences.photoDimming, in: 0...0.75)
                }

                Button("背景写真を削除", role: .destructive) {
                    settingsStore.removeBackgroundImage()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var resetSection: some View {
        Button("すべての設定を初期状態に戻す", role: .destructive) {
            showsResetConfirmation = true
        }
        .font(.subheadline)
        .padding(.top, 2)
    }

    private var informationSection: some View {
        SettingsCard(title: "サポートと情報") {
            Link(
                destination: URL(
                    string: "https://secondclock-support.ariken.chatgpt.site/support"
                )!
            ) {
                Label("サポート・お問い合わせ", systemImage: "questionmark.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            Link(
                destination: URL(
                    string: "https://secondclock-support.ariken.chatgpt.site/privacy"
                )!
            ) {
                Label("プライバシーポリシー", systemImage: "hand.raised")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("SecondClock 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var proStatusCard: some View {
        Group {
            if purchaseManager.isProUnlocked {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("SecondClock Pro")
                            .font(.headline)
                        Text("購入済み・すべての機能を利用できます")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                Button {
                    showsPaywall = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("SecondClock Pro")
                                .font(.headline)
                            Text("背景アニメーション・無制限プリセット・写真背景を解放")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: 4)

                        Image(systemName: "chevron.right")
                            .font(.footnote.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [.indigo.opacity(0.16), .blue.opacity(0.11)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.indigo.opacity(0.18), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint("Pro機能の購入画面を開きます")
            }
        }
    }

    private var themePresets: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("テーマ")
                .font(.subheadline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ClockThemePreset.allCases) { preset in
                        ThemePresetButton(
                            preset: preset,
                            isLocked: preset.requiresPro && !purchaseManager.isProUnlocked
                        ) {
                            if preset.requiresPro && !purchaseManager.isProUnlocked {
                                showsPaywall = true
                            } else {
                                settingsStore.preferences = preset.applying(
                                    to: settingsStore.preferences
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private var backgroundStyleBinding: Binding<ClockBackgroundStyle> {
        Binding(
            get: { effectivePreferences.backgroundStyle },
            set: { newStyle in
                if newStyle.requiresPro && !purchaseManager.isProUnlocked {
                    showsPaywall = true
                } else {
                    settingsStore.preferences.backgroundStyle = newStyle
                }
            }
        )
    }

    private var nightModeBinding: Binding<ClockNightMode> {
        Binding(
            get: { effectivePreferences.nightMode },
            set: { mode in
                if mode.requiresPro && !purchaseManager.isProUnlocked {
                    showsPaywall = true
                } else {
                    settingsStore.preferences.nightMode = mode
                }
            }
        )
    }

    private var scheduleEnabledBinding: Binding<Bool> {
        Binding(
            get: {
                purchaseManager.isProUnlocked && settingsStore.presetSchedule.isEnabled
            },
            set: { isEnabled in
                if isEnabled && !purchaseManager.isProUnlocked {
                    showsPaywall = true
                } else if isEnabled {
                    settingsStore.enablePresetSchedule()
                } else {
                    settingsStore.presetSchedule.isEnabled = false
                }
            }
        )
    }

    private func schedulePresetBinding(isDay: Bool) -> Binding<UUID?> {
        Binding(
            get: {
                isDay
                    ? settingsStore.presetSchedule.dayPresetID
                    : settingsStore.presetSchedule.nightPresetID
            },
            set: { id in
                if isDay {
                    settingsStore.presetSchedule.dayPresetID = id
                } else {
                    settingsStore.presetSchedule.nightPresetID = id
                }
            }
        )
    }

    private func scheduleTimeBinding(isDay: Bool) -> Binding<Date> {
        Binding(
            get: {
                dateForMinutes(
                    isDay
                        ? settingsStore.presetSchedule.dayStartMinutes
                        : settingsStore.presetSchedule.nightStartMinutes
                )
            },
            set: { date in
                let minutes = minutesForDate(date)
                if isDay {
                    settingsStore.presetSchedule.dayStartMinutes = minutes
                } else {
                    settingsStore.presetSchedule.nightStartMinutes = minutes
                }
            }
        )
    }

    private func timeBinding(
        for keyPath: WritableKeyPath<ClockPreferences, Int>
    ) -> Binding<Date> {
        Binding(
            get: { dateForMinutes(settingsStore.preferences[keyPath: keyPath]) },
            set: { settingsStore.preferences[keyPath: keyPath] = minutesForDate($0) }
        )
    }

    private func dateForMinutes(_ minutes: Int) -> Date {
        Calendar.autoupdatingCurrent.date(
            byAdding: .minute,
            value: min(max(minutes, 0), 1_439),
            to: Calendar.autoupdatingCurrent.startOfDay(for: .now)
        ) ?? .now
    }

    private func minutesForDate(_ date: Date) -> Int {
        let components = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func selectFontDesign(_ design: ClockFontDesign) {
        if design.requiresPro && !purchaseManager.isProUnlocked {
            showsPaywall = true
        } else {
            settingsStore.preferences.fontDesign = design
        }
    }

    private func selectFontWeight(_ weight: ClockFontWeight) {
        if weight.requiresPro && !purchaseManager.isProUnlocked {
            showsPaywall = true
        } else {
            settingsStore.preferences.fontWeight = weight
        }
    }

    private func colorBinding(
        for keyPath: WritableKeyPath<ClockPreferences, RGBAColor>
    ) -> Binding<Color> {
        Binding(
            get: { settingsStore.preferences[keyPath: keyPath].color },
            set: { settingsStore.preferences[keyPath: keyPath] = RGBAColor($0) }
        )
    }

    @MainActor
    private func importPhoto(from item: PhotosPickerItem) async {
        guard purchaseManager.isProUnlocked else {
            showsPaywall = true
            selectedPhoto = nil
            return
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw PhotoBackgroundError.invalidImage
            }
            try settingsStore.saveBackgroundImage(data)
        } catch {
            errorMessage = error.localizedDescription
        }
        selectedPhoto = nil
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ClockOptionButton: View {
    let title: String
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                }

                Text(title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isSelected
                    ? Color.accentColor.opacity(0.14)
                    : Color(uiColor: .tertiarySystemGroupedBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        isSelected ? Color.accentColor.opacity(0.7) : .clear,
                        lineWidth: 1.5
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLocked ? "\(title)、Pro" : title)
    }
}

private struct LockedSettingButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                Label("Pro", systemImage: "lock.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.indigo)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ThemePresetButton: View {
    let preset: ClockThemePreset
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                LinearGradient(
                    colors: preset.colors.map(\.color),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 74, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(.black.opacity(0.55), in: Circle())
                            .padding(3)
                    }
                }

                Text(preset.title)
                    .font(.caption2)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLocked ? "\(preset.title)、Pro" : preset.title)
    }
}

private struct AppGroupWarning: View {
    var body: some View {
        Label {
            Text("App Groupが未設定です。ウィジェットへ設定を共有するには、Xcodeの署名設定を確認してください。")
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
        .font(.footnote)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    ContentView()
        .environmentObject(ClockSettingsStore())
        .environmentObject(PurchaseManager())
}

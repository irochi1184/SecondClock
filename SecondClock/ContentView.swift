import PhotosUI
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var settingsStore: ClockSettingsStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var showsSettings = false

    private var effectivePreferences: ClockPreferences {
        settingsStore.effectivePreferences(isProUnlocked: purchaseManager.isProUnlocked)
    }

    var body: some View {
        ZStack {
            ClockBackgroundView(preferences: effectivePreferences)
                .id(settingsStore.backgroundImageRevision)
                .ignoresSafeArea()

            FullScreenClockView(preferences: effectivePreferences)

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
                    .accessibilityHint("表示サイズや背景を変更できます")
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .statusBarHidden(!showsSettings)
        .persistentSystemOverlays(showsSettings ? .visible : .hidden)
        .sheet(isPresented: $showsSettings) {
            ClockSettingsView()
                .environmentObject(settingsStore)
                .environmentObject(purchaseManager)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await purchaseManager.start() }
        }
    }
}

private struct FullScreenClockView: View {
    let preferences: ClockPreferences

    var body: some View {
        GeometryReader { geometry in
            let showsDate = preferences.showDate
            let baseSize = min(
                geometry.size.width / 5.9,
                geometry.size.height * (showsDate ? 0.34 : 0.44)
            )
            let timeFontSize = max(38, baseSize * preferences.displaySize.scale)
            let dateFontSize = max(15, timeFontSize * 0.2)

            VStack(spacing: max(8, timeFontSize * 0.1)) {
                if showsDate {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        Text(
                            context.date,
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

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(
                        context.date,
                        format: .dateTime
                            .hour(.twoDigits(amPM: .omitted))
                            .minute(.twoDigits)
                            .second(.twoDigits)
                    )
                    .font(
                        .system(
                            size: timeFontSize,
                            weight: preferences.fontWeight.swiftUIFontWeight,
                            design: preferences.fontDesign.swiftUIFontDesign
                        )
                    )
                    .monospacedDigit()
                    .allowsTightening(true)
                    .minimumScaleFactor(0.38)
                    .lineLimit(1)
                }
            }
            .foregroundStyle(preferences.textColor.color)
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.3), radius: 9, y: 3)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .center
            )
        }
    }
}

struct ClockSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: ClockSettingsStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var showsResetConfirmation = false
    @State private var showsPaywall = false

    private var effectivePreferences: ClockPreferences {
        settingsStore.effectivePreferences(isProUnlocked: purchaseManager.isProUnlocked)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ClockPreviewCard(
                        preferences: effectivePreferences,
                        imageRevision: settingsStore.backgroundImageRevision
                    )

                    proStatusCard

                    if shouldShowAppGroupWarning {
                        AppGroupWarning()
                    }

                    displaySection
                    typographySection
                    backgroundSection
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
                            Text("写真背景・限定テーマ・グラデーション種類を解放")
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

private struct ClockPreviewCard: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let preferences: ClockPreferences
    let imageRevision: UUID

    private var usesCompactLayout: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        ZStack {
            ClockBackgroundView(preferences: preferences)
                .id(imageRevision)

            VStack(spacing: usesCompactLayout ? 4 : 7) {
                if preferences.showDate {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        Text(
                            context.date,
                            format: .dateTime
                                .year()
                                .month(.wide)
                                .day()
                                .weekday(.wide)
                        )
                        .font(
                            .system(
                                usesCompactLayout ? .caption : .subheadline,
                                design: preferences.fontDesign.swiftUIFontDesign
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    }
                }

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(
                        context.date,
                        format: .dateTime
                            .hour(.twoDigits(amPM: .omitted))
                            .minute(.twoDigits)
                            .second(.twoDigits)
                    )
                    .font(
                        .system(
                            size: (usesCompactLayout ? 36 : 50) * preferences.displaySize.scale,
                            weight: preferences.fontWeight.swiftUIFontWeight,
                            design: preferences.fontDesign.swiftUIFontDesign
                        )
                    )
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                }
            }
            .foregroundStyle(preferences.textColor.color)
            .padding(usesCompactLayout ? 14 : 22)
            .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
        }
        .frame(maxWidth: usesCompactLayout ? 520 : .infinity)
        .aspectRatio(usesCompactLayout ? 2.4 : 1.72, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 20, y: 10)
        .padding(.top, 4)
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

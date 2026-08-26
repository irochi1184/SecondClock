import PhotosUI
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settingsStore: ClockSettingsStore
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var showsResetConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ClockPreviewCard(
                        preferences: settingsStore.preferences,
                        imageRevision: settingsStore.backgroundImageRevision
                    )

                    if !settingsStore.isAppGroupAvailable {
                        AppGroupWarning()
                    }

                    dateSection
                    typographySection
                    backgroundSection
                    resetSection
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("SecondClock")
            .navigationBarTitleDisplayMode(.large)
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
        }
    }

    private var dateSection: some View {
        SettingsCard(title: "表示") {
            Toggle("日付を表示", isOn: $settingsStore.preferences.showDate)

            Text("時刻は24時間形式で、秒まで表示します。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var typographySection: some View {
        SettingsCard(title: "文字") {
            Picker("書体", selection: $settingsStore.preferences.fontDesign) {
                ForEach(ClockFontDesign.allCases) { design in
                    Text(design.title).tag(design)
                }
            }
            .pickerStyle(.segmented)

            Picker("太さ", selection: $settingsStore.preferences.fontWeight) {
                ForEach(ClockFontWeight.allCases) { weight in
                    Text(weight.title).tag(weight)
                }
            }
            .pickerStyle(.segmented)

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
            Picker("種類", selection: $settingsStore.preferences.backgroundStyle) {
                ForEach(ClockBackgroundStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.menu)

            switch settingsStore.preferences.backgroundStyle {
            case .system:
                Text("表示場所に合わせて、iOSが背景の外観を調整します。")
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
    let preferences: ClockPreferences
    let imageRevision: UUID

    var body: some View {
        ZStack {
            ClockBackgroundView(preferences: preferences)
                .id(imageRevision)

            VStack(spacing: 7) {
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
                        .font(.system(.subheadline, design: preferences.fontDesign.swiftUIFontDesign))
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
                            size: 54,
                            weight: preferences.fontWeight.swiftUIFontWeight,
                            design: preferences.fontDesign.swiftUIFontDesign
                        )
                    )
                    .monospacedDigit()
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                }
            }
            .foregroundStyle(preferences.textColor.color)
            .padding(22)
            .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.72, contentMode: .fit)
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
}

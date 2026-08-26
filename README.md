# SecondClock

現在時刻を秒まで表示する、SwiftUI製のiPhoneアプリです。ホーム画面とロック画面のウィジェットに対応しています。

## 主な機能

- アプリ内で現在時刻を1秒ごとに表示
- ホーム画面の小・中サイズウィジェット
- ロック画面の横長ウィジェット
- 日付表示の切替
- 4種類の書体と3種類の太さ
- 文字色の変更
- システム・単色・グラデーション・写真背景
- 写真背景の暗さ調整
- App Groupsを使ったアプリとウィジェット間の設定共有

## 動作条件

- iOS 17.0以降
- Xcode 15.0以降
- Swift 5

## 起動手順

1. `SecondClock.xcodeproj`をXcodeで開きます。
2. `SecondClock`と`SecondClockWidgetExtension`の両方で、ご自身の開発チームを選択します。
3. 必要に応じてBundle Identifierを変更します。
4. 両方のターゲットで同じApp Groupを有効にします。初期値は`group.com.irochi.SecondClock`です。
5. Bundle IdentifierまたはApp Groupを変更した場合は、次のファイル内の値も揃えます。
   - `Shared/SharedClockStorage.swift`
   - `SecondClock/SecondClock.entitlements`
   - `SecondClockWidget/SecondClockWidget.entitlements`
6. `SecondClock`スキームを実機で実行します。
7. ホーム画面またはロック画面を長押しし、「SecondClock」ウィジェットを追加します。

## 秒表示について

ウィジェット拡張を毎秒起動するのではなく、SwiftUIの動的なタイマー表示を利用しています。その日の午前0時からの経過時間を表示することで、24時間形式の現在時刻として動作します。

iPhoneの常時表示が暗くなっている間や、省電力状態では、iOSの判断によって秒の描画が抑制されることがあります。通常のウィジェットからこの挙動を強制的に変更することはできません。

## 背景について

「システム」は、利用場所に合わせてiOSが背景を調整できる設定です。ホーム画面をそのまま透かす完全な透明表示は、WidgetKitの正式な仕組みでは提供されていません。

## 構成

```text
SecondClock/          アプリ本体
SecondClockWidget/    ウィジェット拡張
Shared/               両ターゲットで共有する設定と表示部品
```

## ライセンス

MIT License

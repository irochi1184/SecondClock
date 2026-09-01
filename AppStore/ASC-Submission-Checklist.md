# App Store Connect 初回提出チェックリスト

## 1. 契約・アカウント

- [ ] Apple Developer Programが有効
- [ ] App Store ConnectのPaid Apps Agreementを締結
- [ ] 税務情報を提出
- [ ] 振込先銀行口座を登録
- [ ] EUで配信する場合、DSAのTrader Statusと連絡先表示を確認

## 2. Identifiers・署名

- [ ] App ID `com.irochi.SecondClock`を登録
- [ ] App IDでApp GroupsとIn-App Purchaseを有効化
- [ ] Widget App ID `com.irochi.SecondClock.Widget`を登録
- [ ] App Group `group.com.irochi.SecondClock`を登録し、両ターゲットへ追加
- [ ] Distribution証明書とApp Storeプロビジョニングを確認

## 3. ASCで新規アプリを作成

- [ ] プラットフォーム：iOS
- [ ] アプリ名：`SecondClock – 秒まで見える時計`を取得（不可の場合は`Brand/Naming-Proposal.md`のB案へ切替）
- [ ] プライマリ言語：日本語
- [ ] Bundle ID：`com.irochi.SecondClock`
- [ ] SKU：`SECONDCLOCK-IOS-001`
- [ ] User Access：Full Access

## 4. 商品ページ

- [ ] `Metadata/ja-JP.md`からサブタイトル、説明、キーワード等を入力
- [ ] 主カテゴリをユーティリティに設定
- [ ] `Screenshots/Final-ja/`の横向き4枚（2868×1320）を順番どおりアップロード
- [ ] 公開済みのサポートURL、マーケティングURL、プライバシーURLを入力
- [ ] コンテンツ配信権：第三者コンテンツを含まない
- [ ] 広告識別子：使用しない

## 5. プライバシー・年齢・輸出

- [ ] `Review/App-Privacy-Answers.md`に沿ってApp Privacyを回答
- [ ] `Review/Age-Rating-Answers.md`に沿って年齢制限質問へ回答
- [ ] Export Compliance：非免除暗号化を使用しない
- [x] `ITSAppUsesNonExemptEncryption = NO`をビルド設定へ追加済み

## 6. SecondClock Pro

- [ ] 非消耗型商品を作成
- [ ] Product ID：`com.irochi.SecondClock.pro.lifetime`
- [ ] `Review/In-App-Purchase.md`から表示名・説明・審査メモを入力
- [ ] 初期価格を確定（提案：700円）
- [ ] `Review/iap-review.png`を審査用スクリーンショットへ登録
- [ ] Cleared for Saleを有効化
- [ ] バージョン1.0.0の「In-App Purchases and Subscriptions」へ商品を追加

## 7. ビルド・審査

- [x] エメラルド＋オレンジの採用アイコンをAssetsへ反映
- [ ] XcodeでAny iOS Device向けRelease Archiveを作成
- [ ] Validate Appを通す
- [ ] Distribute App > App Store Connect > Upload
- [ ] ASCで処理済みビルド1を選択
- [ ] Review Contactの氏名、電話番号、メールアドレスを入力
- [ ] `Review/App-Review-Notes.md`をReview Notesへ貼り付け
- [ ] 自動リリースか手動リリースを選択（初回は手動を推奨）
- [ ] アプリ本体と初回IAPを同じ提出に含めて審査へ送信

## 本人しか確定できない項目

- 法的氏名、審査連絡先の電話番号
- 銀行・税務情報、契約同意
- 配信国、価格、EU Trader Status
- 審査提出ボタンの実行

import { detailMetadata } from "../siteMetadata";

export const metadata = detailMetadata(
  "プライバシーポリシー — SecondClock",
  "SecondClockのデータ取扱いに関する方針。",
);

export default function PrivacyPage() {
  return (
    <main className="shell">
      <nav className="nav" aria-label="メインナビゲーション">
        <a className="brand" href="/">SecondClock</a>
        <div className="navLinks"><a href="/support">サポート</a></div>
      </nav>
      <article className="document">
        <p className="eyebrow">PRIVACY POLICY</p>
        <h1>プライバシーポリシー</h1>
        <p className="documentLead">最終更新日：2026年8月28日</p>

        <h2>基本方針</h2>
        <p>SecondClockは、アカウント登録、広告、アクセス解析、独自サーバーを使用せず、開発者がユーザーの個人データを収集・送信することはありません。</p>
        <h2>端末内に保存される情報</h2>
        <p>時計の表示設定と、ユーザーが背景として選択した写真は、アプリとウィジェットが共有する端末内のローカル領域に保存されます。これらは開発者や第三者へ送信されません。</p>
        <h2>写真へのアクセス</h2>
        <p>写真背景を選択する操作を行った場合に限り、iOSの写真選択画面を通じてユーザーが指定した画像を読み込みます。フォトライブラリ全体を閲覧または収集することはありません。</p>
        <h2>アプリ内課金</h2>
        <p>SecondClock Proの購入処理はAppleのStoreKitを通じて行われます。開発者は支払情報を受け取りません。アプリは、Pro機能を提供するためにAppleが発行する購入資格を端末上で確認します。</p>
        <h2>保存期間と削除</h2>
        <p>設定や背景写真は、ユーザーがアプリ内で削除・初期化するか、アプリを削除するまで端末内に保存されます。背景写真は設定画面の「背景写真を削除」から削除できます。</p>
        <h2>第三者提供</h2>
        <p>開発者が収集するデータがないため、第三者への販売、共有、追跡目的での利用はありません。</p>
        <h2>変更</h2>
        <p>機能や法令の変更に応じて本ポリシーを更新する場合があります。重要な変更は、このページで告知します。</p>
        <h2>お問い合わせ</h2>
        <p>本ポリシーに関するお問い合わせは、<a href="mailto:ken.office.arita@gmail.com">ken.office.arita@gmail.com</a>までご連絡ください。</p>

        <hr />
        <h2 lang="en">Privacy Policy — English Summary</h2>
        <p lang="en">SecondClock does not use accounts, ads, analytics, or developer-operated servers, and the developer does not collect personal data. Clock settings and user-selected background photos remain on the device. Purchases are processed by Apple through StoreKit; the developer never receives payment details. Contact: <a href="mailto:ken.office.arita@gmail.com">ken.office.arita@gmail.com</a>.</p>
      </article>
    </main>
  );
}

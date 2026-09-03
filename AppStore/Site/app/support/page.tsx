import { detailMetadata } from "../siteMetadata";

export const metadata = detailMetadata(
  "サポート — SecondClock",
  "SecondClockの使い方、購入の復元、お問い合わせ先。",
);

export default function SupportPage() {
  return (
    <main className="shell">
      <nav className="nav" aria-label="メインナビゲーション">
        <a className="brand" href="/">SecondClock</a>
        <div className="navLinks"><a href="/privacy">プライバシー</a></div>
      </nav>
      <article className="document">
        <p className="eyebrow">SUPPORT</p>
        <h1>サポート</h1>
        <p className="documentLead">問題が解決しない場合は、下記の連絡先までお問い合わせください。</p>

        <h2>よくある質問</h2>
        <h3>購入済みのPro機能を復元したい</h3>
        <p>アプリ右上の歯車から「SecondClock Pro」を開き、「購入を復元」を選択してください。購入時と同じApple IDをご利用ください。</p>
        <h3>ウィジェットへ設定が反映されない</h3>
        <p>アプリを一度開いて設定を保存した後、ウィジェットを追加し直してください。省電力状態では秒表示の更新が抑制される場合があります。</p>
        <h3>写真は外部へ送信されますか</h3>
        <p>送信されません。選択した写真は端末内で処理され、アプリとウィジェットが利用するローカル領域にのみ保存されます。</p>

        <h2>お問い合わせ</h2>
        <div className="contactCard">
          <p><strong>メール</strong><br /><a href="mailto:ken.office.arita@gmail.com">ken.office.arita@gmail.com</a></p>
          <p><strong>不具合報告</strong><br /><a href="https://github.com/irochi1184/SecondClock/issues">GitHub Issues</a></p>
          <p>お問い合わせには、端末名、iOSのバージョン、問題が起きた操作を添えてください。</p>
        </div>
      </article>
    </main>
  );
}

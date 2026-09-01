import { rootMetadata } from "./siteMetadata";

export const generateMetadata = rootMetadata;

export default function Home() {
  return (
    <main className="shell">
      <nav className="nav" aria-label="メインナビゲーション">
        <a className="brand" href="/">SecondClock</a>
        <div className="navLinks">
          <a href="/support">サポート</a>
          <a href="/privacy">プライバシー</a>
        </div>
      </nav>

      <section className="hero">
        <p className="eyebrow">FULL-SCREEN CLOCK FOR iPHONE</p>
        <h1>秒まで、<br />美しく見える。</h1>
        <p className="lead">
          SecondClockは、好きな色や写真で仕立てる全画面時計です。
          縦向きにも横向きにも、ウィジェットにも対応します。
        </p>
        <div className="featurePills" aria-label="主な機能">
          <span>秒表示</span><span>横向き対応</span><span>背景カスタマイズ</span>
        </div>
      </section>

      <section className="featureGrid" aria-label="SecondClockの特徴">
        <article>
          <p className="featureNumber">01</p>
          <h2>開いた瞬間、時計。</h2>
          <p>余計な操作なしで、現在時刻を秒まで全画面表示。縦向きでも横向きでも見やすく整います。</p>
        </article>
        <article>
          <p className="featureNumber">02</p>
          <h2>空間に合わせて選べる。</h2>
          <p>サイズ、書体、色、単色・グラデーション・写真背景を組み合わせて、自分の時計を作れます。</p>
        </article>
        <article>
          <p className="featureNumber">03</p>
          <h2>ウィジェットでも秒表示。</h2>
          <p>ホーム画面とロック画面に対応。アプリで選んだデザインを、いつもの画面にも反映できます。</p>
        </article>
      </section>

      <section className="proPanel">
        <div>
          <p className="eyebrow">SECONDClock PRO</p>
          <h2>もっと自由に、買い切りで。</h2>
        </div>
        <p>5種類のグラデーション、写真背景と暗さ調整、夕焼け・桜・夜空の限定テーマをアプリ内課金で解放できます。サブスクリプションではありません。</p>
      </section>

      <footer className="footer">
        <p>© 2026 SecondClock</p>
        <div><a href="/support">サポート</a><a href="/privacy">プライバシーポリシー</a></div>
      </footer>
    </main>
  );
}

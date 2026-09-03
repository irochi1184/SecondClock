# SecondClock Web Site

App Store ConnectのサポートURL、マーケティングURL、プライバシーポリシーURLとして使用する公式サイトです。

## ページ

- `/`：製品紹介
- `/support`：FAQ・問い合わせ先
- `/privacy`：プライバシーポリシー

## ローカル確認

Node.js 22.13.0以降を使用します。

```bash
npm install
npm run build
npm test
```

Sites project IDは`.openai/hosting.json`に保存されています。本番URLは`https://secondclock-support.ariken.chatgpt.site`です。

2026年8月28日にSitesのアクセス設定を`public`へ変更済みです。サイトに記載した問い合わせメールアドレスも一般公開されています。

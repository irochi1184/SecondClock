import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "SecondClock",
  description: "秒まで美しく見える、iPhoneの全画面時計。",
  icons: {
    icon: "/icon.png",
    shortcut: "/icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja">
      <body>{children}</body>
    </html>
  );
}

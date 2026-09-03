import type { Metadata } from "next";
import { headers } from "next/headers";

async function currentBaseURL() {
  const requestHeaders = await headers();
  const host = requestHeaders.get("host") ?? "localhost:3000";
  const protocol = host.startsWith("localhost") ? "http" : "https";
  return new URL(`${protocol}://${host}`);
}

export async function rootMetadata(): Promise<Metadata> {
  const base = await currentBaseURL();
  const title = "SecondClock — 秒まで美しく見える時計";
  const description = "全画面表示とウィジェットに対応した、シンプルで美しいiPhone時計アプリ。";
  const image = new URL("/og.png", base).href;

  return {
    metadataBase: base,
    title,
    description,
    openGraph: { title, description, type: "website", url: base, images: [image] },
    twitter: { card: "summary_large_image", title, description, images: [image] },
  };
}

export function detailMetadata(title: string, description: string): Metadata {
  return {
    title,
    description,
    openGraph: { title, description, images: [] },
    twitter: { card: "summary", title, description, images: [] },
  };
}

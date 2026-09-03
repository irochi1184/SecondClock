import assert from "node:assert/strict";
import test from "node:test";

async function render(pathname) {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}-${pathname}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request(`http://localhost${pathname}`, {
      headers: { accept: "text/html" },
    }),
    {
      ASSETS: {
        fetch: async () => new Response("Not found", { status: 404 }),
      },
    },
    {
      waitUntil() {},
      passThroughOnException() {},
    },
  );
}

async function expectPage(pathname, expectedText) {
  const response = await render(pathname);
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);
  const html = await response.text();
  assert.match(html, /SecondClock/);
  assert.match(html, expectedText);
  assert.doesNotMatch(html, /Your site is taking shape|Building your site/);
}

test("renders the product page", async () => {
  await expectPage("/", /秒まで/);
});

test("renders the support page", async () => {
  await expectPage("/support", /購入を復元/);
});

test("renders the privacy policy", async () => {
  await expectPage("/privacy", /個人データを収集/);
});

// Shared setup for Noor app e2e tests.
//
// The Flutter web build renders to canvas with semantics disabled until the
// offscreen `flt-semantics-placeholder` button is pressed (Playwright cannot
// tap it: 1px at -1,-1, outside the viewport). Clicking it via evaluate
// switches the full accessibility tree on, after which `screen` semantic
// locators resolve the app's real labels.
export async function enableFlutterSemantics(browser: {
  locator: (css: string) => {
    waitFor: (options?: { state?: string; timeout?: number }) => Promise<void>;
  };
  evaluate: (source: string) => Promise<unknown>;
}): Promise<void> {
  await browser
    .locator('canvas')
    .waitFor({ state: 'attached', timeout: 60_000 });
  const clicked = await browser.evaluate(
    `(() => { const el = document.querySelector('flt-semantics-placeholder'); if (!el) return 'missing'; el.click(); return 'clicked'; })()`,
  );
  if (clicked !== 'clicked') throw new Error('semantics placeholder missing');
}

import { test } from '@e2e-dev/web';
import { expect } from 'e2e';

import { enableFlutterSemantics } from './helpers.js';

// Most important user flow: a reader opens the Mushaf and sees Quran page 1.
// Fully deterministic (no model): onboarding is skipped when present (fresh
// profiles), the Quran library opens from the bottom navigation, the Mushaf
// FAB opens the reader, and the semantic heading plus routed URL prove the
// exact settled page.
test('a reader opens the Mushaf and sees Quran page 1', async ({
  app,
  screen,
  browser,
}) => {
  await app.open('/');
  await enableFlutterSemantics(browser);

  if (await screen.getByRole('button', 'Skip').isVisible()) {
    await screen.getByRole('button', 'Skip').tap();
  }
  await expect(screen.getByText('Home')).toBeVisible({ timeout: 30_000 });

  await screen.getByRole('button', 'Quran').tap();
  await expect(screen.getByText(/Holy Quran/)).toBeVisible({
    timeout: 30_000,
  });

  await screen.getByText('Mushaf').tap();
  // The slider live-region merges the indicator leaf, so pin the semantic
  // heading (page/surah/juz context) plus the routed URL.
  await expect(
    screen.getByRole('heading', /Page 1 of 604/),
  ).toBeVisible({
    timeout: 30_000,
  });
  await expect(browser).toHaveURL(/mushaf/);
});

// Deep-link contract (QUR-04): a cold boot straight into a page link parks
// on onboarding WITHOUT losing the target; completing onboarding lands on
// that exact page with header, footer, and indicator in agreement. When the
// profile already saw onboarding, the link resolves directly.
test('a cold deep link survives onboarding onto that exact page', async ({
  app,
  screen,
  browser,
}) => {
  await app.open('/quran/mushaf?page=2');
  await enableFlutterSemantics(browser);

  if (await screen.getByRole('button', 'Skip').isVisible()) {
    await screen.getByRole('button', 'Skip').tap();
  }
  await expect(
    screen.getByRole('heading', /Page 2 of 604/),
  ).toBeVisible({
    timeout: 60_000,
  });
  await expect(browser).toHaveURL(/mushaf\?page=2/);
});

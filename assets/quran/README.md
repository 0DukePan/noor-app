# Quran text assets

Bundled Quran content. Every file here is covered by
[`docs/content-manifest.json`](../../docs/content-manifest.json); changing any
of it invalidates the scholarly review — read
[`docs/content-pipeline.md`](../../docs/content-pipeline.md) first.

## Files

- `quran_uthmani.json` — Uthmani script, 6,236 verses. Sidecar:
  `quran_uthmani.sha256`.
- `quran_pages.json` — the 604-page mushaf map (which verses are on each page).
- `surahs.json` — surah metadata (names, verse counts, revelation place).
- `translations/en_sahih.json` — English translation (the `en.sahih` edition).
- `translations/ar_muyassar.json` — Arabic Muyassar text bundled with the
  translations.

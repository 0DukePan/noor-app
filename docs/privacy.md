# Privacy

The one-page version of the app's privacy design, written so that the claims
can be checked against the code. The store-facing forms are in
[store/data-safety.md](store/data-safety.md) and the hosted policy page in
[store/privacy-policy.html](store/privacy-policy.html); the engineering threat
model is in [../SECURITY.md](../SECURITY.md).

## Data inventory

| What | Stored where | Leaves the device? | Control |
|---|---|---|---|
| Tadabbur notes (personal reflections) | Device, AES-encrypted before storage | Never | Delete in-app; no backup of the key |
| Bookmarks, reading progress, adhkar counts, qada records, hifz/FSRS state | Device (Hive boxes) | Never | Clear app data / uninstall |
| Settings, theme, prayer method, offsets | Device (Hive boxes) | Never | In-app settings |
| Location | Used in memory; a trusted-location cache stays on device | Never sent by the app | OS permission; revocable |
| Search queries | In memory; hadith search index/cache on device | Never | Clear cache in settings |
| Crash reports | Only if a DSN was provided at build time | Stack traces, optionally | Off unless built with `--dart-define=SENTRY_DSN` |
| Usage counters | Device (Hive `analytics` box) | Only with opt-in **and** a configured endpoint | Off by default; settings toggle |
| Recitation audio | Device cache (optional) | — | Streams from a public CDN when you play a remote reciter |

## The counters, exactly

`lib/core/services/analytics_service.dart` accepts exactly eight event names:
`app_open`, `prayer_viewed`, `surah_opened`, `tafsir_opened`, `hadith_opened`,
`adhkar_completed`, `search_used`, `qibla_viewed`. Nothing else can be
recorded — an unknown name is dropped rather than stored. A snapshot is a map
of counts: no identity, no timestamps, no content, no device information. The
upload endpoint is `null` by default, so the default build never sends
anything; when the owner configures a first-party endpoint, counts are cleared
only after a 2xx response.

## Crash reports, exactly

Sentry is initialized only when `SENTRY_DSN` is supplied at build time.
`sendDefaultPii: false`, `attachScreenshot: false`, `tracesSampleRate: 0.0`
(no performance tracing), and no session tracking. A release built without the
DSN sends nothing. Test builds are DSN-free.

## Network calls, exhaustively

Only three Dart call sites make requests:

| Call site | Purpose | When |
|---|---|---|
| `quran_audio_engine.dart` | Stream/download recitation from `cdn.islamic.network` | Only when you play a remote reciter |
| `api_fetcher_service.dart` | Mosque lookup fallback (`masjidnear.me`); additional fetcher capabilities are unused by core flows | Only when the mosque finder is used |
| `analytics_service.dart` | Opt-in counters | Only with opt-in + configured endpoint |

Fonts are bundled and `GoogleFonts.config.allowRuntimeFetching = false`, so no
font fetches happen. Reverse geocoding for a city label is performed by the
platform geocoder (documented in the store forms). There is no account, no
sync, and no backend — `DefaultPrivacyPolicy.kCloudSyncAvailable` is `false`.

## Deletion and portability

There is no account and no server copy, so deletion is local: "clear app data"
or uninstall removes everything, including the encryption key in platform
secure storage. The flip side is documented in [../SECURITY.md](../SECURITY.md):
because the key never leaves the platform keystore, encrypted notes cannot be
restored onto a new device from a backup — they fail closed and show empty
rather than leaking.

## How to verify

- Counters: `lib/core/services/analytics_service.dart` (`allowedEvents`).
- Crash options: the `SentryFlutter.init` block in `lib/main.dart`.
- Encryption: `lib/core/domain/policies/privacy_policy.dart` +
  `lib/core/services/secure_key_service.dart`.
- Network surface: the table above lists every Dart call site; grep for
  `http.` under `lib/` to confirm nothing else exists.

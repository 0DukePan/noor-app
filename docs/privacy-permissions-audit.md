# Permissions & privacy audit (Phase 7.9)

Static audit of the shipped manifest against code call sites and the
published claims (`docs/privacy.md`, `docs/store/data-safety.md`,
`docs/store/privacy-policy.html`). Checked 2026-10-07 against this checkout;
re-run before every release (manifest, call sites, and forms change
together).

## Android permission → feature → call site

| Permission | Feature | Request site (just-in-time?) | Verdict |
|---|---|---|---|
| INTERNET, ACCESS_NETWORK_STATE | Recitation streaming, mosque fallback, opt-in counters | `quran_audio_engine.dart`, `api_fetcher_service.dart`, `analytics_service.dart` (docs/privacy.md exhaustively lists all three) | Match; no other call sites make requests |
| ACCESS_FINE/COARSE_LOCATION | Prayer times, Qibla | `location_trust_engine.dart:61` inside `getTrustedLocation` (flow call, cached fallback on denial); `qibla_page.dart:94`; status reads in `prayer_health_check.dart:154` | Just-in-time; never at startup; denial yields explicit fallback, never a precise-location claim |
| SCHEDULE_EXACT_ALARM, WAKE_LOCK, RECEIVE_BOOT_COMPLETED | Adhan alarms | Scheduler service (alarm set only after user enables adhan) | Scoped to user-enabled feature |
| FOREGROUND_SERVICE, FOREGROUND_SERVICE_MEDIA_PLAYBACK | Background recitation | `quran_audio_engine.dart` audio session (playback category) | Scoped to playback |
| POST_NOTIFICATIONS, ACCESS_NOTIFICATION_POLICY | Adhan / smart reminders | `smart_notification_engine.dart:107`; status+request in `prayer_health_check.dart:135,287` | Just-in-time with denial path |
| VIBRATE | Haptics/tasbih feedback | UI feedback only | No data implication |
| REQUEST_IGNORE_BATTERY_OPTIMIZATIONS | Alarm reliability | `prayer_health_check.dart:212,299` (status check + request in health flow) | Request exists in code; surfaced through the health-check flow, not silently |

## iOS (`ios/Runner/Info.plist`)

- `NSLocationWhenInUseUsageDescription` → prayer/Qibla (in-use only, no
  background location mode declared).
- `UIBackgroundModes` → audio (verify the array holds only `audio` at
  release time).

## Claims check

- Data-safety form ("one category only: crash logs, DSN-gated") matches
  `analytics_service.dart` (8 fixed event names, null endpoint by default)
  and Sentry init (DSN-gated, `sendDefaultPii: false`, no screenshots,
  no tracing).
- `docs/privacy.md` "only three Dart call sites make requests" — re-verified
  by grep for `http.`/`HttpClient`/`Dio` outside those files: no new network
  call sites were added by the Mushaf remediation (audio engine change
  reuses the same CDN path; token generator is a build-time tool).
- Fonts bundled, runtime fetching disabled — no font network.
- No account/sync/backend: `DefaultPrivacyPolicy.kCloudSyncAvailable`
  remains `false`; Hive data stays on device; deletion = clear data/uninstall.

## Open items (not blockers for the remediation, required at release)

- Re-run this table against the release binary (manifest merger can add
  permissions from plugins).
- Data-safety "crash logs" answer assumes the release is built with a DSN;
  a DSN-free build collects nothing — pick the matching form answer.
- `UIBackgroundModes` array contents must be confirmed in the archive.

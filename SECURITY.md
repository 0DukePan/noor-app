# Security policy

## Reporting a vulnerability

Use GitHub's private reporting on this repository: **Security → Report a
vulnerability** (private security advisories). Please do not open a public
issue for anything exploitable.

Include the app version (`pubspec.yaml`), the platform and OS version, and a
minimal reproduction. This is a single-maintainer project, so responses are
best-effort — but every report is read, and you will be credited in the
advisory once a fix ships if you want to be.

## Supported versions

Only the latest release is supported. Fixes are not backported to older builds.

## What this project is (and is not)

Noor is an offline-first Android/iOS application. There is **no first-party
server, no account system, and no backend database**. The security-relevant
surface is therefore:

1. The content that ships inside the app (Quran, hadith, tafsir, adhkar).
2. The user data stored on the device.
3. A small set of outbound network calls, all of which are optional or
   content-fetching — none of them identify the user.

## Threat model

### Assets worth protecting

| Asset | Where it lives | What a leak would mean |
|---|---|---|
| Tadabbur notes (personal reflections) | On device, AES-encrypted before storage | Private religious reflection |
| Reading progress, bookmarks, adhkar counts, qada records | On device (plain local Hive/SQLite) | Worship habits, not identity |
| Location | On device only; used for prayer times and qibla | Physical presence |
| Content integrity | Bundled assets + SHA-256 sidecars | Misquoted scripture or hadith |
| Opt-in usage counters | On device; uplifted only if the owner configures an endpoint | Aggregate counts only |

### What never leaves the device

- The full text the user reads, their notes, bookmarks, progress, adhkar
  counts, qada records, and search queries.
- Location. Prayer times and the qibla bearing are computed on-device; the
  coordinates are never transmitted. Device geocoding (reverse geocoding for a
  city name) is performed by the platform's own geocoder.
- Any identifier. There is no account, no device ID, no advertising ID, and no
  third-party analytics SDK.

### What can leave the device, and only when enabled

| Channel | Default | What it reveals |
|---|---|---|
| Reciter audio streaming / download | Off until the user plays a remote reciter | The CDN sees an IP address and which surah is requested |
| Mosque lookup fallback | Off until the user searches for mosques | The lookup API sees an IP address and a coarse search area |
| Opt-in usage counters | Off; requires explicit opt-in in Settings **and** an endpoint configured by the build owner | An allowlist of 8 aggregate event counts — no identity, no timestamps, no content |
| Crash reports | Off unless a Sentry DSN is supplied at build time | Stack traces with `sendDefaultPii: false`, no screenshots, tracing disabled |

The counters are strictly allowlisted in
`lib/core/services/analytics_service.dart`; anything not on the list is dropped
rather than stored. The crash path is configured in `lib/main.dart`.

### Trust boundaries

- **Bundled content vs. runtime network.** All core content is bundled and
  checksummed; the network is used only for optional audio and the mosque
  fallback. A compromised CDN cannot change what the app reads offline.
- **The app has no privileged backend.** There is nothing server-side to
  breach, because there is no server.
- **No secrets in the repository.** The Android keystore, `key.properties`,
  and any Sentry DSN are never committed (`--dart-define` at build time).

### Out of scope

- A compromised or rooted device / jailbroken OS, and a malicious OS vendor.
- An attacker with the unlocked device and the app's own UI.
- Malicious edits made locally to a build the user compiled themselves.

## Cryptography (encrypted notes)

- **Algorithm and format:** AES via `package:encrypt`, a fresh random IV for
  every write (prepended to the ciphertext, base64-encoded, `iv:ciphertext`).
  The same plaintext never produces the same ciphertext.
- **Key handling:** 32 random bytes from `Random.secure()` are generated on
  first use by `SecureKeyService` and kept in the platform secure storage
  (Android Keystore-backed encrypted preferences, iOS Keychain, Windows DPAPI).
  The key is never hardcoded, never derived from a device identifier, and never
  leaves the device.
- **Failure handling:** a corrupted or undecryptable note returns an empty
  string instead of throwing or emitting partial plaintext.
- **Known limitation (backup/restore):** the ciphertext can be included in OS
  backups; the key cannot, because platform keystores do not travel between
  devices. Encrypted notes therefore fail closed after a device migration —
  they become unreadable rather than exposed. There is no key escrow and no
  remote wipe, because there is no account.

## Permissions and why each exists

Android permissions are declared in `android/app/src/main/AndroidManifest.xml`;
iOS usage strings in `ios/Runner/Info.plist`. There is no hardware permission
beyond this list (no image capture, contacts, SMS, or broad-storage access).

| Permission | Why | Requested when |
|---|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE` | Optional reciter streaming/download and the mosque fallback lookup; core features work with networking off | Never prompted (install-time) |
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Compute prayer times and the qibla bearing on-device | Only when the user opens prayer/qibla features |
| `SCHEDULE_EXACT_ALARM`, `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED` | The adhan must ring at the exact prayer time and survive reboots | When adhan alarms are enabled |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Keep adhan/recitation audio playing in the foreground service | While audio plays |
| `ACCESS_NOTIFICATION_POLICY` | Optional DND override so the adhan is audible (mosque mode) | Only when the user enables the DND override |
| `POST_NOTIFICATIONS`, `VIBRATE` | Adhan and adhkar reminders | When reminders are enabled |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Prevent the OS from deferring adhan alarms | Only when the user enables the exemption |
| iOS `UIBackgroundModes: audio` | Background recitation playback | n/a |

## Supply chain

- **Dependency scanning in CI.** `.github/workflows/ci.yml` runs Google's
  OSV-Scanner against `pubspec.lock` on every push and pull request, so a
  vulnerable package version fails the build instead of shipping.
- **SBOM.** The same job emits a CycloneDX SBOM (`tools/generate_sbom.py`) and
  uploads it as a build artifact for every run.
- **Pinned toolchain.** CI pins the Flutter version the project is verified
  against instead of tracking `stable`; goldens and analyzer rules cannot
  drift underneath the build.
- **SDK floor.** `pubspec.yaml` requires Dart ≥ 3.11.0 / Flutter ≥ 3.41.0 —
  the first releases containing the fix for CVE-2026-27704 (path traversal in
  `pub` package extraction). Older SDKs are refused at resolve time.
- **No runtime dependency downloads.** Fonts are bundled and runtime fetching
  is explicitly disabled; the app never pulls code or fonts at startup.

## Content integrity as a security property

For a religious app, a silently altered text is a security incident. Every
content set ships with a SHA-256 sidecar and appears in the machine-readable
manifest checked by `dart run tool/verify_content_checksums.dart` (also run in
the release job), and the scholarly-review tracker (`docs/scholarly-review.md`)
pins each set to a reviewed hash. See `docs/content-pipeline.md`.

## Hardening notes for future changes

- Do not log user content (notes, search queries, coordinates). Logging is
  limited to service-init failure names and error objects.
- Any new outbound call must be opt-in or content-only, and documented here and
  in `docs/privacy.md`.
- Any change to the analytics allowlist, the Sentry options, or a permission
  needs an entry in `CHANGELOG.md` and a review of this document.

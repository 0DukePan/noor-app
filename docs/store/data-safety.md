# Data safety form answers — Google Play

For the Play Console «Data safety» section. The same answers map to Apple's
App Privacy form.

## Does your app collect or share any required user data types?

**One category only: crash logs.** Every user data type is device-only and
unchecked.

| Category | Answer |
|---|---|
| App info and performance → Crash logs | **Collected** — crash reports via Sentry, sent only when the build is configured with a `SENTRY_DSN` |
| Location | Not collected (used on-device only for prayer times) |
| Personal info | Not collected |
| Financial info | Not collected |
| Health & fitness | Not collected |
| Messages | Not collected |
| Photos & videos | Not collected |
| Audio files | Not collected |
| Contacts | Not collected |
| Calendar | Not collected |
| Web bookmarks | Not collected |
| App activity | Not collected (see the opt-in analytics note below) |
| Other app diagnostics | Not collected |
| Device or other identifiers | Not collected |

Crash-log details for the form's follow-up questions:

- **What is collected**: crash stack traces, app version, device model, OS
  version. No user identifiers, no screenshots, no IP-derived location, no
  personal data — the Sentry client runs with `sendDefaultPii=false`,
  `attachScreenshot=false` and `tracesSampleRate=0`.
- **Purpose**: app functionality / diagnostics (fixing crashes). Not used for
  advertising. Not shared with third parties beyond the crash processor.
- **Optional?**: crash reporting is inert in a build without a DSN; there is no
  user-facing toggle.
- **Encrypted in transit**: yes (HTTPS to Sentry).
- **Retention / deletion**: retained under Sentry's retention policy; cannot be
  deleted from inside the app.

## Is data encrypted? / Can users request data deletion?

- **Encryption in transit**: Yes — crash reports, and the optional public-API
  fallback downloads (content and audio, HTTPS). Nothing else leaves the
  device.
- **Deletion mechanism**: account-less app. All user data (reading progress,
  bookmarks, settings, encrypted notes) lives on-device only and is deleted
  when the app is uninstalled. Crash reports cannot be deleted from inside the
  app — state this in the form's optional explanation field.

## Data types declared as "collected" that are actually device-only

Play has no "device-only" bucket — leave every user-data type unchecked. If the
form forces an explanation, paste:

> All user data (reading progress, bookmarks, settings, encrypted notes) is
> stored exclusively on the user's device within the app. No user data is
> transmitted, shared, or collected. The only data leaving the device is
> anonymous crash-report data (Sentry), sent only when the build is configured
> with a crash-reporting endpoint. The app has no account system, no
> third-party analytics, and no advertising SDKs.

## Opt-in first-party analytics (off by default)

The app also ships its own aggregate-only counters (no third-party SDK, no
identifiers, no timestamps, no content). They transmit only when **both** are
true: the user opts in from settings, and the build sets a first-party
endpoint. If you ship a build with an endpoint configured, additionally
declare:

| Category | Answer |
|---|---|
| App activity → Other actions | Collected — opt-in aggregate counts only, not linked to any user |

…and answer "Data is not linked to the user", "Not used for advertising".
If no endpoint is configured (the default), leave App activity unchecked.

## App Access / Promotions (AdMob etc.)

- No ads SDKs, no analytics SDKs, no third-party SDKs beyond:
  - `sentry_flutter` (crash reporting only, only if a DSN is configured at
    build time, PII-free)
  - optional public REST APIs (quran/tafsir/prayer fallback content,
    HTTPS, no personal data sent)
- Target audience: all ages (no COPPA-specific designation needed; no
  data collection from children).

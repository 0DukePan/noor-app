# Data safety form answers — Google Play

For the Play Console «Data safety» section. Because the app collects nothing,
every answer is the most conservative one. The same answers map to Apple's
App Privacy form.

## Does your app collect or share any required user data types?
**No.** Answer every category with «No» / «Not collected»:

| Category | Answer |
|---|---|
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
| App activity | Not collected |
| App diagnostics | Not collected |
| Device or other identifiers | Not collected |

## Is data encrypted? / Can users request data deletion?
- **Encryption in transit**: Not applicable (no data leaves the device; the
  optional public-API fallback downloads use HTTPS).
- **Deletion mechanism**: Not applicable — data lives only on-device;
  uninstalling the app deletes everything. (State this in the form's
  optional explanation field.)

## Data types declared as "collected" that are actually device-only
Play has no "device-only" bucket — leave everything unchecked. If the form
forces an explanation, paste:

> All data (reading progress, bookmarks, settings, encrypted notes) is stored
> exclusively on the user's device within the app. No data is transmitted,
> shared, or collected. The app makes no account system and no analytics or
> advertising SDKs are present.

## App Access / Promotions (AdMob etc.)
- No ads SDKs, no analytics SDKs, no third-party SDKs beyond:
  - `sentry_flutter` (crash reporting only, only if a DSN is configured at
    build time, PII-free)
  - optional public REST APIs (quran/tafsir/prayer fallback content,
    HTTPS, no personal data sent)
- Target audience: all ages (no COPPA-specific designation needed; no
  data collection from children).

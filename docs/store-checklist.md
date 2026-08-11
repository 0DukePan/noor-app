# Store Release Checklist

Everything needed to publish Noor on Google Play and the App Store.

## 1. Google Play — Data Safety form

The in-app privacy sheet (Settings → الخصوصية والبيانات) states exactly what the
app does. Map it to the Play form as follows:

| Question | Answer | Notes |
|---|---|---|
| Does the app collect or share personal data? | **No** | Everything is on-device; no accounts required |
| Location | **Not collected** | GPS is read on-device only, never transmitted |
| Crash logs | **Collected** (via Sentry) | Only non-PII crash reports; declare under "App diagnostics" |
| Photos/videos | No | |
| Audio files | No | |
| Financial info | No | |
| Messages | No | |
| Personal info (name/email) | No | Only if the user opts into cloud sync later |
| Ads | No | |
| Can users request data deletion? | N/A (no account data) | |

Check the "Data is encrypted in transit" (HTTPS for audio/CDN) and
"Data can't be deleted automatically" where applicable.

## 2. Google Play — Permissions declarations

Declared permissions and their justifications (required by Play review):

- **Location (approximate + precise)** — calculating prayer times and the
  Qibla direction from the device's position. Requested only when the user
  opens prayer/qibla features.
- **Notifications (POST_NOTIFICATIONS)** — adhan and adhkar reminders.
- **Alarms & reminders (SCHEDULE_EXACT_ALARM)** — adhan must ring at the exact
  prayer time even in Doze. (Play requires declaring the app as
  "alarm/clock"-adjacent; explain the religious-use case in the declaration.)
- **Battery optimisation exemption (REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)** —
  so adhan alarms are not deferred. Declare its purpose.
- **Do not disturb access (ACCESS_NOTIFICATION_POLICY)** — optional override
  so the adhan is heard in DND.
- **Camera** — optional AR Qibla overlay.
- **Foreground service (media playback)** — playing the adhan from the alarm.

## 3. App Store — Privacy nutrition labels

- **Data Not Collected** is NOT true because of Sentry crash reports:
  declare "Diagnostics → Crash Data" only. No other categories.
- Background modes: "Audio" is declared in Info.plist (UIBackgroundModes) for
  background recitation — mention it in the review notes.

## 4. Signing & build

1. Create the release keystore (keep the file and passwords safe — you cannot
   update the app without them). Windows/PowerShell:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\create_keystore.ps1
   ```
   or manually (needs a JDK):
   ```bash
   keytool -genkey -v -keystore android/app/noor-release.jks \
     -keyalg RSA -keysize 4096 -validity 10000 -alias noor
   ```
2. `tools\create_keystore.ps1` writes `android/key.properties` for you
   (never commit it). Manual shape:
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=noor
   storeFile=../app/noor-release.jks
   ```
   (`android/key.properties.example` shows the shape; `key.properties` and
   `*.jks` are gitignored.)
3. Build locally or via CI:
   ```bash
   flutter build appbundle --release    # Play
   flutter build apk --release          # sideload/CI artifact
   ```
   The GitHub Actions workflow builds a debug-signed APK on every push. To get
   a properly signed release AAB from CI, add these repository secrets
   (Settings > Secrets and variables > Actions): `KEYSTORE_BASE64` (base64 of
   `noor-release.jks`, e.g. `[Convert]::ToBase64String([IO.File]::ReadAllBytes('...'))`),
   `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS=noor` — the
   `build-appbundle` job then runs automatically on push.

## 5. iOS (requires a Mac)

```bash
flutter build ipa --release   # after signing setup in Xcode
```
- Set the bundle identifier to a unique id (currently `com.noor.app`).
- Upload via Xcode/Transporter.
- Permission strings are already in `ios/Runner/Info.plist` (Arabic).

## 6. Store assets

- **Icon**: already generated (`assets/icon/app_icon.png` applied to
  Android/iOS launchers).
- **Screenshots** (required): take on a phone: home dashboard, Quran mushaf,
  hadith library, prayer times, adhkar, qibla.
- **Feature graphic** (Play, 1024×500).
- **Description**: Arabic + English short/long descriptions.
- **Privacy policy URL**: required by both stores — host the privacy sheet
  text (Settings → الخصوصية والبيانات) on a page.

## 7. Versioning

- `pubspec.yaml` version: `1.0.0+1` — bump `+N` per release build.
- CHANGELOG.md exists — keep it updated.

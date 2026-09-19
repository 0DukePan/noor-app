# 001 — Flutter as the application framework

**Status:** Accepted (restated 2026-09-18)

## Context

Noor targets Android and iOS from a single maintainer. The UI is Arabic-first
(RTL by default, LTR fallback), depends on Arabic typography (Amiri for Quran
text, Cairo for UI), and needs deep native integration: SQLite, background
audio, exact alarms, a magnetometer, geolocation and home-screen widgets. The
content is large (hundreds of MB) and must work without a network.

## Decision

Build on Flutter (stable channel), with a pinned toolchain: CI pins Flutter
3.44.9 because text metrics, golden rendering and analyzer rules shift under an
unpinned `stable`.

## Consequences

- One codebase, one test suite, two platforms.
- Native capabilities come through plugins (`sqflite`, `just_audio`,
  `flutter_compass`, `geolocator`, `flutter_local_notifications`,
  `home_widget`), which is why the web target is unsupported and documented as
  such.
- Widget tests and golden files are part of the quality bar, and the pinned
  version is what keeps them stable (see `.github/workflows/ci.yml`).

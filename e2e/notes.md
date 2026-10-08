# e2e setup notes (Noor app)

Web target drives the Flutter web release build (`build/web`) — the same
Dart code and UI as Android. Rebuild it after app changes:
`flutter build web --release`. The runner serves it via `e2e/serve-web.cjs`
(starts/stops automatically per run).

## Why web, not mobile (2026-10-07)

The instructed path was `@e2e-dev/mobile` on an Android emulator. It is
blocked by two upstream Windows bugs in `agent-device` (both reported to
the e2e team):

1. Daemon can never start: log truncation calls `ftruncate()` on an
   append-mode handle → Node/Windows answers `EPERM` (proven with a minimal
   repro). Ref `01a117d7-1e16-7f3e-bc71-e2b4d61343f8`.
2. Even past that, the daemon ownership handshake never establishes on
   Windows (daemon registers a port, client reports ownership-unproven,
   orphans a daemon per invocation). Ref `01a117d7-3781-7941-a8d4-eab0374404ac`.

Local-only workaround (not committed, re-apply after `npm install`):
swallow the single `ftruncateSync` in
`node_modules/agent-device/dist/src/daemon-registration-owner.js`.
The emulator (`android-34/google_apis/x86_64`), a debug APK
(`build/app/outputs/flutter-apk/app-debug.apk`), and package
`com.noor.app` are ready for the day upstream fixes land; then point the
target at `mobile({ platform: 'android' })` with that `appPath`.

`AGENT_DEVICE_STATE_DIR` can redirect daemon state, but does not fix
either bug.

## Models

- Agent steps first used OpenCode Console (`opencodeConsole`), but the
  workspace has Zen turned off, and no local model existed — so the suite
  runs fully local via Ollama (no sign-in, no key).
- The example test needs no model at all.

## Web-e2e techniques (Flutter web renders to canvas)

- Semantics are off until the 1px offscreen `flt-semantics-placeholder`
  button is clicked via `browser.evaluate` (Playwright refuses: outside the
  viewport). `tests/helpers.ts#enableFlutterSemantics` does this; every
  full page load resets it, so call it after each `app.open`.
- After that, `screen` semantic locators resolve real labels. Text matching
  is exact: prefer `{ exact: false }` substrings and stable orthography
  (page-map text uses U+0671 `ٱ`, not plain aleph).
- The slider live-region merges the page-indicator leaf: pin the semantic
  heading (`Page N of 604, …`) instead of indicator text.
- Product fixes this e2e work already produced: web path-URL strategy +
  imperative-URL reflection (`SWP-02`), pending deep link across onboarding
  (`QUR-04`), home garnish hardening (`SWP-03`).
- Open threads: second-`app.open`-in-one-test route resolution; cold
  deep-link widget coverage hangs the runner (under investigation).

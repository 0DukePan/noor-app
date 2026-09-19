# 005 — Offline-first: bundle the core, keep the network optional

**Status:** Accepted (restated 2026-09-18)

## Context

The app's value is highest where connectivity is absent or untrusted: in a
mosque, on a plane, on a metered connection, in a basement. The trust story
also depends on nothing leaving the device by default
([privacy.md](../privacy.md)). At the same time a few features are naturally
network-shaped: streaming recitation, and looking up nearby mosques.

## Decision

All core content and computation is bundled or local. The network is used only
for explicitly optional features, and never for core reading, prayer or qibla.
There is no account, no sync and no backend:
`DefaultPrivacyPolicy.kCloudSyncAvailable = false`, and every `canSyncToCloud`
category returns `false` while that constant is false.

## Consequences

- Startup never touches the network; the offline behaviour matrix lives in
  [offline-first.md](../offline-first.md).
- Network-dependent features fail softly: remote recitation errors in the UI,
  the mosque finder returns an empty list.
- Adding sync later is a deliberate, reviewable change (flip the constant) that
  also requires a backend, a consent screen and a privacy review — it is not
  just a code path.
- The opt-in usage counters ship with a `null` endpoint by default, so the
  default build is a pure local counter.

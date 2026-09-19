# 004 — Riverpod for state management

**Status:** Accepted (restated 2026-09-18)

## Context

The app has a lot of asynchronous, per-feature state derived from local
services: prayer times for today, search results, paginated hadith lists,
reading progress, day-state, audio state. Widget tests need to pump pages with
deterministic data, and services are initialized once in `main()` as static
singletons.

## Decision

Use `flutter_riverpod`. Providers (including `FutureProvider`/`StreamProvider`)
hold state per feature under `presentation/providers/`; tests override
providers instead of mocking global singletons.

## Consequences

- `lib/core/di/` is intentionally empty: there is no separate DI container.
  Service initialization order is controlled in `main.dart`
  (`Future.wait` over independent initializers), and providers bridge services
  into the widget tree.
- Widget tests routinely override providers (for example
  `prayerDataProvider` and `homeDataProvider` in the accessibility tests), which
  is what keeps page tests deterministic without touching disk.
- Ticks and time-dependent UI use stream providers so tests can inject a fixed
  time rather than waiting on timers.

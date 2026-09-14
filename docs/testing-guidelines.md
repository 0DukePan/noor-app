# Testing guidelines (learned the hard way)

Short, practical notes for writing tests in this repo. Each entry is a trap
that cost real debugging time — read this before writing a widget test.

## Hive + `testWidgets` (fake-async)

- **Persisted writes never complete inside fake-async.** `box.put(...)` /
  `box.delete(...)` futures are real disk I/O; under `testWidgets` they hang
  forever. If a test must persist before asserting, wrap the write in
  `await tester.runAsync(...)` — e.g.
  `await tester.runAsync(HiveService.setOnboardingSeen);`
  (reads via an already-open box's in-memory cache are fine without this).
- **Opening a NEW box in the test body never completes either** — not with
  `runAsync`, not with fake pumps. **Pre-open every box the code under test
  touches in `setUp`/`setUpAll` (real zone);** body-zone `openBox` calls for
  the same names then hit the cache and complete via microtask. Verified:
  a body-zone `openBox` of a fresh name hangs forever; the identical call
  for a pre-opened name returns instantly.
- **Puts on an OPEN box poison the zone permanently — the nastiest trap
  here.** An un-awaited `put` schedules write-flush timers that never fire
  in the fake zone; from then on `pumpAndSettle` spins forever, test
  timeouts never fire, `Hive.close()` hangs, and the file never exits.
  Consequences: (a) never tap UI that triggers puts on an open box in a
  widget test — drive put-bearing logic through the real notifier inside
  `tester.runAsync` (puts complete in the real zone) and pump to render;
  (b) cover put-heavy logic in plain-zone unit tests instead;
  (c) puts against NEVER-OPENED boxes are harmless (they pend at the open,
  never reaching the write queue — e.g. qada's fire-and-forget saves).
  Production corollary (applied to `MemorizationNotifier.reviewCard`): keep
  in-memory state updates synchronous and ahead of persistence, qada-style.
- **Teardown order matters.** `Hive.deleteFromDisk()` closes boxes but leaves
  them registered; the next test's `openBox` then reuses a *closed* box and
  every `put` throws `HiveError: Box has already been closed` as an unhandled
  async error — intermittent failures under full-suite load. Always:
  `await Hive.close();` **then** `await Hive.deleteFromDisk();` in teardown.
- **Match Hive's box generic type.** `HiveService` opens boxes as
  `Box<Map<dynamic, dynamic>>`. Opening the same name with a different generic
  (e.g. `Box<dynamic>`) makes `Hive.box(...)` throw on reuse. Use the same
  type the app code uses.
- `HiveError extends Error`, not `Exception` — a plain `on Exception` will not
  catch box-lifecycle failures.

## Periodic providers & timers

- Riverpod `Stream.periodic` providers (e.g. `dayStateProvider`,
  `currentTimeProvider`) leave pending timers that fail the test at teardown.
  Override them with one-shot values:
  `provider.overrideWith((ref) => Stream.value(...))`.
- `flutter_animate` schedules a 0ms timer when each card mounts. If the
  mounted animations are finite, `await tester.pumpAndSettle(...)` flushes
  them; if anything repeats (e.g. a shimmer with `controller.repeat()`),
  use fixed `pump(duration)` calls instead and unmount at the end.
- End animation-heavy tests with `await tester.pumpWidget(const SizedBox())`
  so `dispose()` cancels subscriptions/timers.

## Platform channels never throw — they hang

- Unmocked method channels (geolocator, compass, PackageInfo, path_provider,
  haptics) do **not** throw `MissingPluginException` in this Flutter version:
  the request is delegated to the real messenger and the future never
  completes. Mock what a page touches:
  `setMockMethodCallHandler(SystemChannels.platform, (call) async => null)`
  for haptics; `setMockStreamHandler` for event channels; return a map from
  the PackageInfo/geolocator channels when the code parses their response.
- `FutureProvider`s that hit such channels (e.g. `homeDataProvider`) must be
  `overrideWith`-ed in widget tests; a never-completing `Completer` pins the
  loading branch without leaving a pending timer.

## General

- Fixed sleeps as "wait for async init" are always wrong: they flake under
  load and slow the suite. Prefer awaiting an explicit readiness signal (the
  notifiers expose `ready` for this) or polling the observable with a
  deadline. For real asset I/O under `testWidgets`, a **single generous
  `runAsync` window** (e.g. 1500ms) works where sliced `runAsync` polling
  loops don't drain pending fake-zone continuations.
- **flutter_test quirk:** a second `rootBundle.loadString` of the *same*
  asset within one testWidgets isolate never completes (the first load's
  cached future poisons repeat loads). If two tests in one file load the same
  asset (e.g. surah 1 tafsir), use a different asset per test — or a single
  test per asset. Direct plain `test()` calls are unaffected.
- **Slivers don't build below-fold rows.** A `ListView` only materializes
  visible children (+cache extent), so `find` misses offscreen content and
  taps on it warn-and-miss. Scroll first: `scrollUntilVisible` for UNIQUE
  finders (it throws on multi-match — use manual `drag` loops with a cap for
  shared header/tile titles), then assert/tap while visible. Note scrolling
  away can un-build rows again — assert each target while it is on screen.
- The claim guard (`test/mojibake_guard_test.dart`) scans every user-facing
  doc — if a stripped term reappears in README/store/API_SOURCES, that's an
  intentional honesty regression, not a test annoyance.
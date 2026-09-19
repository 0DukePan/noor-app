# Accessibility

What the app guarantees today, how it is tested, and what is still open. This
file is the source of truth for accessibility claims — if a claim here is not
backed by a test below, it does not belong here.

Enforced by `test/widget/a11y_test.dart` (run with `flutter test`) on every
push, using Flutter's own accessibility guidelines:

| Guideline | Requirement |
|---|---|
| `androidTapTargetGuideline` | every tappable node is at least 48x48 dp |
| `iOSTapTargetGuideline` | every tappable node is at least 44x44 dp |
| `labeledTapTargetGuideline` | every tappable node announces a non-empty label |

## Covered today

| Screen | What is asserted |
|---|---|
| Main navigation shell | 5 destinations, each labelled, each reports its selected state, all >= 48x48 |
| Tasbih | counter announces the count (`liveRegion`) and is activatable by a screen reader; presets announce label + selected state; reset is labelled |
| Prayer times | full populated timeline meets all three guidelines; the icon-only AppBar actions announce what they open; the timeline bell toggle keeps a >= 48 dp target |
| Home dashboard | full dashboard meets all three guidelines; and it lays out **without a RenderFlex overflow at 1.3x and 2.0x text scale** (`test/widget/text_scale_test.dart`, Arabic/RTL) |
| Hadith reader | previous/next controls are labelled and emulated as buttons |
| Tafsir reader | ayah stepper buttons are labelled; the inline view's compact controls (bookmark, full view, compare) keep a >= 48 dp rendered tap target, asserted by size (`tafsir_widgets_test.dart`) |
| Qibla | the purely visual compass has a spoken heading — bearing to the Kaaba and the current device heading (`a11yQiblaCompass`) — and the page meets the tap-target guideline |

Semantics labels come from `lib/l10n` (`a11yPrevious`, `a11yNext`,
`a11yTasbihCount`, `a11yQiblaCompass`, plus reused existing keys) — never
hardcoded, so the Arabic and English trees stay in parity with the ARB check.

## Two implementation rules

Both are load-bearing; without them the guideline tests fail:

1. **Wrap the tap target, disable the gesture's own semantics.** A
   `GestureDetector` publishes its own tap node, so nesting it inside a
   `Semantics(label: ...)` leaves an unlabelled tappable node in the tree. The
   pattern is `Semantics(..., onTap: ..., child: GestureDetector(excludeFromSemantics: true, ...))`.
2. **A `Semantics` node that claims to be a button must expose `onTap`.**
   `excludeSemantics: true` drops the child's action, so without an explicit
   `onTap` a screen reader would announce a button it cannot activate.

## Deliberately not gated

`textContrastGuideline` is not part of the suite. Widget tests render text with
the placeholder Ahem font, whose glyph boxes make contrast measurement
meaningless — it would gate on a rendering artifact rather than on the real
theme. Contrast is covered by `test/widget/theme_matrix_test.dart` and the
manual pass in `docs/qa-checklist.md`.

## Known gaps (tracked, not fixed)

- **Semantics coverage is partial.** The guideline tests cover the screens in
  the table above. The remaining feature modules (quran index, mushaf, hadith
  library, adhkar, hifz, search, settings, profile, audio) have no explicit
  `Semantics` labels yet.
- **Dynamic type is partially verified.** The home dashboard is gated at 1.3x
  and 2.0x (Arabic/RTL). The other dense screens — prayer timeline rows, hadith
  lists, the mushaf — are not yet covered by an automated scale test and may
  still overflow at large text sizes. The zero-constraint/compact icon buttons
  found while closing this gap (tafsir bookmark and inline controls, qibla
  calibration, prayer bell) now render at >= 48 dp; `visualDensity.compact`
  subtracts 8 dp from any minimum, which is what had pushed them to 40 dp.
- **Manual screen-reader pass.** TalkBack and VoiceOver have not been run on a
  physical device for any flow — see `docs/qa-checklist.md`, which carries the
  device-side steps.
- **LTR visual audit.** Direction-dependent arrows in the hadith reader and
  tafsir reader now follow `Directionality` (see the CHANGELOG: they were
  hardcoded for RTL and inverted for the English/LTR locale). Trailing
  chevrons elsewhere in the app have not all been audited for LTR.

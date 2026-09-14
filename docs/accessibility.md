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
| Prayer times | full populated timeline meets all three guidelines; the icon-only AppBar actions announce what they open |
| Home dashboard | full dashboard meets all three guidelines |
| Hadith reader | previous/next controls are labelled and emulated as buttons |
| Tafsir reader | ayah stepper buttons are labelled |

Semantics labels come from `lib/l10n` (`a11yPrevious`, `a11yNext`,
`a11yTasbihCount`, plus reused existing keys) — never hardcoded, so the Arabic
and English trees stay in parity with the ARB check.

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

- **Coverage is partial.** The guideline tests cover the four screens above.
  The remaining feature modules (quran index, mushaf, hadith library, adhkar,
  hifz, qibla, search, settings, profile, audio) have no explicit `Semantics`
  labels yet. Qibla in particular is a purely visual compass and needs a
  spoken heading, which is its own design question.
- **Compact icon buttons.** The tafsir reader's stepper uses
  `VisualDensity.compact`, which renders below 48 dp. It is labelled but not
  yet re-sized.
- **Dynamic type.** No golden matrix at 1.0/1.3/1.6/2.0 text scale yet; large
  text can still overflow in dense rows.
- **Manual screen-reader pass.** TalkBack and VoiceOver have not been run on a
  physical device for any flow — see `docs/qa-checklist.md`, which carries the
  device-side steps.
- **LTR visual audit.** Direction-dependent arrows in the hadith reader and
  tafsir reader now follow `Directionality` (see the CHANGELOG: they were
  hardcoded for RTL and inverted for the English/LTR locale). Trailing
  chevrons elsewhere in the app have not all been audited for LTR.

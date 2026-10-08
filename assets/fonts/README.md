# Font Assets

Bundled, offline-only fonts. No runtime font fetching is permitted
(`GoogleFonts.config.allowRuntimeFetching = false` in `lib/main.dart`; Qur'an
text uses `fontFamily: 'Amiri'` directly).

## Files

| File | Family | Version (TTF name table) | Licence |
|---|---|---|---|
| `Amiri-Regular.ttf` | Amiri Regular | 1.002 | SIL OFL 1.1 (`OFL-Amiri.txt`) |
| `Amiri-Bold.ttf` | Amiri Bold | 1.002 | SIL OFL 1.1 (`OFL-Amiri.txt`) |
| `Cairo-Variable.ttf` | Cairo Regular (variable) | 3.130 | SIL OFL 1.1 (`OFL-Cairo.txt`) |

Versions were read from the binaries' `name` tables
(`nameID 1/4/5/13/14`); the licence description is embedded in each file and
copied in full beside it. SIL OFL 1.1 permits Android/iOS binary bundling.

## Roles

- **Amiri**: Qur'an text (Uthmani shaping, end-of-ayah glyphs). Selected in
  `docs/content-decision-record.md`.
- **Cairo Variable**: UI chrome and metadata.

## Sources

- Amiri: https://github.com/aliftype/amiri
- Cairo: https://fonts.google.com/specimen/Cairo

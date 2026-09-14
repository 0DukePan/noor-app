# README media

`demo.gif` is the animation embedded at the top of [README.md](../README.md).
`frames/` holds the still PNGs it is built from — they double as store-listing
screenshots and as the individual scenes.

Everything here lives under `docs/` on purpose: `assets/` directories declared
in `pubspec.yaml` are bundled into the APK and counted against the CI asset
budget (`tools/check_assets_size.py`, 230 MB), so README media must never go
there.

## Regenerating

```bash
# 1. Render the frames (writes docs/media/frames/*.png).
#    NOT part of `flutter test` — it lives outside test/, so CI never runs it
#    and never depends on platform font rendering.
flutter test --update-goldens tool/readme_capture/readme_capture_test.dart

# 2. Assemble the GIF (writes docs/media/demo.gif).
dart run tool/readme_capture/build_gif.dart
```

`tool/readme_capture/readme_capture_test.dart` renders real app pages at phone
size with the **real** Cairo/Amiri/MaterialIcons fonts loaded, so the Arabic
shapes correctly. (The deterministic golden tests deliberately render text as
Ahem boxes to pin layout; do not copy that behaviour here.) It captures real
bundled data wherever it can — the mushaf scene shows genuine Uthmani verses,
the adhkar scene the real library. Nothing in this harness invents scripture or
hadith.

## Known limitations

- Frames are 390x844 (one phone at 1x). `matchesGoldenFile` captures at 1x, and
  upscaling adds size without detail, so the GIF is used at its native size.
- Icons and the digit rendering are capture-only approximations in one respect:
  the design system also names `Outfit`/`Inter`, which are not bundled (on a
  device they resolve to the system font). The harness aliases those families to
  the bundled Cairo font so glyphs do not render as tofu boxes.
- The captured pages are pumped with fake/overridden providers — the home,
  prayer and hadith screens use fixture data, not a live device.

## Replacing it with a real device recording

A real recording is strictly better and the README does not care where the file
came from:

1. Record the app on a real device (Android: `adb shell screenrecord`; iOS:
   the screen-recording control centre toggle), ideally a 15–25 s pass over
   home → mushaf → hadith → prayer → adhkar → tools.
2. Convert to GIF at ≤4 MB, ~420–600 px wide, 10–15 fps. With ffmpeg:
   `ffmpeg -i recording.mp4 -vf "fps=12,scale=480:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse" docs/media/demo.gif`
3. Drop it in as `docs/media/demo.gif` — no README change needed.

Keep the recording Arabic-UI (the app's primary locale) and free of personal
data: the home screen shows a city name and reading progress.

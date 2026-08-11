# On-device QA checklist — Noor (نور)

Run this on a **real phone** (Android + iPhone if possible) before submitting
to the stores. Automated coverage (analyze, unit/widget/golden tests, and the
emulator integration test in CI) runs in parallel, but the items below can
only be checked on real hardware.

## 0. Fresh install

- [ ] Install the release APK/AAB on a clean device (factory reset or cleared
      app data). First launch shows the import progress screen, then onboarding.
- [ ] Reinstall the app *over* an older build: settings, bookmarks, and
      memorization progress must survive the upgrade.
- [ ] Background the app (Home button) during the first-launch import and
      reopen it — no crash, no stuck screen.

## 1. Onboarding & navigation

- [ ] Skip onboarding → home opens; onboarding never shows again.
- [ ] Complete onboarding (all 5 steps) → home opens.
- [ ] Bottom nav: الرئيسية / القرآن / الحديث / الأذكار / الأدوات all open;
      selected tab label is visible; taps are responsive.
- [ ] Back button exits the app from home, pops pages elsewhere.
- [ ] Rotation is locked to portrait.

## 2. Quran

- [ ] Surah list loads (114 suras), opens surah 1 (الفاتحة); verse text renders
      with diacritics correctly.
- [ ] Mushaf page navigation (604 pages), bookmarks, continue-reading card
      resumes the right ayah.
- [ ] Audio playback: play an ayah with sound ON and OFF (silent mode). Test
      background playback (lock screen) and the lock-screen controls.
- [ ] Khatmah planner opens; tafsir sheet opens for a verse.

## 3. Hadith

- [ ] Book library loads (9 books + Nawawi 40); opening a book shows chapters.
- [ ] Read a hadith; open sharh (شرح) and scholar mode; tag a hadith.
- [ ] Advanced search: search «الرحمن» — results must include Quran AND hadith
      AND adhkar rows (alef-wasla/ta' marbuta/hamza-insensitive).
- [ ] Search a diacritized word with the keyboard fully vowelled
      (e.g. «الرَّحْمَٰن») — must return the same results as the plain word.
- [ ] Quiz, memorization (FSRS cards), learning statistics open and persist.
- [ ] Settings → storage → "clear search index" works and search still returns
      results after rebuild.

## 4. Prayer / qibla / tools

- [ ] Prayer times show for the real GPS location; change the calculation
      method in إعدادات الصلاة → times change accordingly.
- [ ] Adhan sounds at the right time (or fires in preview if you don't want to
      wait). Test with notifications disabled then enabled.
- [ ] Qibla compass points plausibly (compare with a physical compass / mosque
      direction in your city); AR mode shows the camera feed.
- [ ] Qada tracker, tasbih counter, day-state card on home update correctly.

## 5. Adhkar

- [ ] Morning/evening/post-prayer lists open; counters increment; navigation
      between items works; completion state persists.
- [ ] Sleep/wakeup/general collections open from their cards.
- [ ] **Content review**: every adhkar text and its source label (المصدر) has
      been checked by a qualified reader; fix any typo/attribution in
      `assets/adhkar/*.json`.

## 6. Settings & data

- [ ] Dark mode follows the system and renders correctly (no unreadable text).
- [ ] Notification settings toggle actually enables/disables adhan + adhkar
      notifications.
- [ ] Home-screen widget (if supported on the device) updates after prayer
      times change.
- [ ] About / privacy sheet opens and states the honest policy; "clear data"
      actions work.

## 7. Robustness

- [ ] Airplane mode: app fully works offline (all content is bundled).
- [ ] Low storage warning path: app doesn't crash when storage is nearly full.
- [ ] Rapid tab switching (10+ switches in 5 s) — no jank/crash.
- [ ] No red error screens at any point; check logcat for
      `FATAL EXCEPTION` / `Unhandled Exception`.

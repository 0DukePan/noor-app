// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Noor';

  @override
  String get navHome => 'Home';

  @override
  String get navQuran => 'Quran';

  @override
  String get navHadith => 'Hadith';

  @override
  String get navAdhkar => 'Adhkar';

  @override
  String get navTools => 'Tools';

  @override
  String get dbImportTitle => 'Preparing the hadith database...';

  @override
  String get dbImportSubtitle =>
      'The first launch imports the hadith collections. This happens only once.';

  @override
  String get appTagline =>
      'A comprehensive Islamic app serving as a digital worship environment';

  @override
  String get commonRetry => 'Retry';

  @override
  String get homeLoadError => 'Couldn\'t load data';

  @override
  String get homeContinueReading => 'Continue reading';

  @override
  String get homeFavorites => 'Favorites';

  @override
  String get homeTodayAdhkar => 'Today\'s adhkar';

  @override
  String get homePropheticLight => 'Prophetic light';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsHeader => 'Customize the app';

  @override
  String get settingsHeaderSubtitle => 'Make the app fit your needs';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsReading => 'Reading';

  @override
  String get settingsFontSize => 'Font size';

  @override
  String get settingsGeneral => 'General settings';

  @override
  String get settingsHaptics => 'Haptics';

  @override
  String get settingsHapticsSubtitle => 'Tactile feedback on interaction';

  @override
  String get settingsClearCache => 'Clear cache';

  @override
  String get settingsClearCacheSubtitle =>
      'Delete temporary data to free space';

  @override
  String get settingsAdvanced => 'Advanced settings';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Morning/evening adhkar, prayer alerts';

  @override
  String get settingsStorage => 'Storage & performance';

  @override
  String get settingsStorageSubtitle => 'Manage stored data';

  @override
  String get settingsPrivacy => 'Privacy & data';

  @override
  String get settingsPrivacySubtitle => 'We collect no personal data';

  @override
  String get settingsAbout => 'About the app';

  @override
  String get settingsAppName => 'Noor';

  @override
  String get settingsAboutBody =>
      'A comprehensive Islamic app — Quran, hadith, prayer times, adhkar and tafsir';

  @override
  String settingsAppVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsPrivacyRowOffline =>
      'The app works offline for core content (Quran, hadith, tafsir, adhkar).';

  @override
  String get settingsPrivacyRowTracking =>
      'No trackers; anonymous usage statistics are off by default and only collected if you enable them. Your data is never shared with any third party.';

  @override
  String get settingsPrivacyRowLocation =>
      'Your location is used on-device only to compute prayer times and the qibla; it is never sent to any server.';

  @override
  String get settingsPrivacyRowCrash =>
      'Only on a technical crash, error data goes to Sentry with no personally identifying information.';

  @override
  String get settingsPrivacyRowNotes =>
      'Your personal notes (tadabbur mihrab) are encrypted and kept on your device only.';

  @override
  String get settingsPrivacyRowSync =>
      'No cloud sync: all your data (bookmarks, statistics, progress) stays on your device.';

  @override
  String get settingsPrivacyRowNetwork =>
      'The app may contact public servers only to fetch missing data (tafsir/recitation/times) without sending any of your data.';

  @override
  String get settingsClearCacheTitle => 'Clear cache';

  @override
  String get settingsClearCacheBody =>
      'Are you sure? The downloaded recitation cache and search index will be deleted and rebuilt automatically when needed.';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsClear => 'Clear';

  @override
  String get settingsCacheCleared => 'Cache cleared successfully';

  @override
  String get settingsAnalytics => 'Usage statistics';

  @override
  String get settingsAnalyticsOff =>
      'Off by default — anonymous counts stay on your device';

  @override
  String get settingsAnalyticsOn => 'On — anonymous usage counts are collected';

  @override
  String get settingsAnalyticsPrivacy =>
      'Anonymous usage statistics: off by default; if you enable them, only aggregate counts are collected — never your identity or content.';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifAdhkarSection => 'Adhkar reminders';

  @override
  String get notifMorning => 'Morning adhkar';

  @override
  String get notifMorningSubtitle => '30 minutes after Fajr';

  @override
  String get notifEvening => 'Evening adhkar';

  @override
  String get notifEveningSubtitle => '30 minutes before Maghrib';

  @override
  String get notifPrayerSection => 'Prayer notifications';

  @override
  String get notifBeforePrayer => 'Pre-prayer alert';

  @override
  String notifBeforeMinutes(int minutes) {
    return '$minutes minutes before';
  }

  @override
  String get notifBeforeLabel => 'Before prayer by';

  @override
  String notifMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get notifDailySection => 'Daily reading reminder';

  @override
  String get notifKhatmah => 'Daily khatmah reminder';

  @override
  String notifAtTime(String time) {
    return 'At $time';
  }

  @override
  String get notifDisabled => 'Off';

  @override
  String get notifReminderTime => 'Reminder time';

  @override
  String get notifQuietSection => 'Quiet hours';

  @override
  String get notifQuiet => 'Quiet hours';

  @override
  String notifQuietRange(int start, int end) {
    return 'From $start:00 to $end:00';
  }

  @override
  String get notifApply => 'Apply settings';

  @override
  String get notifUpdated => 'Notifications updated';

  @override
  String get notifKhatmahMessage => 'Time for your daily reading portion';

  @override
  String get storageTitle => 'Storage & performance';

  @override
  String get storageCacheSection => 'Cache';

  @override
  String get storageManageSection => 'Manage data';

  @override
  String get storageSilentSection => 'Quiet interface';

  @override
  String get storageSurahs => 'Saved surahs';

  @override
  String get storageHadiths => 'Saved hadiths';

  @override
  String get storageAdhkar => 'Saved adhkar';

  @override
  String get storageClearTitle => 'Clear cache';

  @override
  String get storageClearSubtitle => 'Reload data from source';

  @override
  String get storageRefreshTitle => 'Refresh statistics';

  @override
  String get storageRefreshSubtitle => 'Re-read displayed data';

  @override
  String get storageSilentBody =>
      'Noor uses a quiet interface with no annoying popups. All notifications appear gently and disappear automatically.';

  @override
  String get storagePreviewGentle => 'Preview gentle notification';

  @override
  String get storagePreviewSuccess => 'Preview success notification';

  @override
  String get storageGentleSample => 'This is a gentle notification sample';

  @override
  String get storageSavedOk => 'Saved successfully!';

  @override
  String get storageCacheCleared => 'Cache cleared';

  @override
  String get storageStatsUpdated => 'Statistics updated';

  @override
  String get qadaTitle => 'Qada tracker';

  @override
  String get qadaTabPrayer => 'Prayer';

  @override
  String get qadaTabFast => 'Fasting';

  @override
  String get qadaCongrats => 'Congratulations!';

  @override
  String get qadaCongratsBody => 'You have completed this record';

  @override
  String get qadaPraiseGod => 'Praise be to God';

  @override
  String get qadaEmptyPrayer => 'No missed prayers to make up';

  @override
  String get qadaEmptyFast => 'No fasting days to make up';

  @override
  String get qadaAdd => 'Add';

  @override
  String get qadaAddNew => 'Add new record';

  @override
  String qadaProgress(int done, int total) {
    return 'Done: $done of $total';
  }

  @override
  String get qadaComplete => 'Complete';

  @override
  String qadaRemainingPrayer(int remaining) {
    return 'Remaining: $remaining prayers';
  }

  @override
  String qadaRemainingFast(int remaining) {
    return 'Remaining: $remaining days';
  }

  @override
  String get qadaDidPrayer => 'I made up one prayer';

  @override
  String get qadaDidFast => 'I fasted one day';

  @override
  String get qadaAddPrayerTitle => 'Add prayers to make up';

  @override
  String get qadaAddFastTitle => 'Add fasting days to make up';

  @override
  String get qadaNameLabel => 'Name (optional)';

  @override
  String get qadaNameHint => 'E.g. 2020 prayers';

  @override
  String get qadaCountLabel => 'Count *';

  @override
  String get qadaCountPrayerHint => 'Number of prayers';

  @override
  String get qadaCountFastHint => 'Number of days';

  @override
  String get qadaNotesLabel => 'Notes (optional)';

  @override
  String get qadaNotesHint => 'Any extra notes';

  @override
  String get qadaInvalidCount => 'Please enter a valid count';

  @override
  String get qadaDefaultPrayerName => 'Qada prayers';

  @override
  String get qadaDefaultFastName => 'Fasting days';

  @override
  String get prayerTitle => 'Prayer times';

  @override
  String get prayerQadaTooltip => 'Missed prayers';

  @override
  String get prayerLoadError => 'Couldn\'t load prayer times';

  @override
  String get prayerDayDone => 'Today\'s prayers are done';

  @override
  String prayerNext(String name) {
    return 'Next prayer: $name';
  }

  @override
  String get prayerUntilAdhan => 'Time until adhan';

  @override
  String get psetTitle => 'Prayer settings';

  @override
  String get psetAdhanSection => 'Adhan & alerts';

  @override
  String get psetMosqueSection => 'Mosque mode';

  @override
  String get psetMethodSection => 'Calculation method';

  @override
  String get psetOffsetsSection => 'Seasonal offsets';

  @override
  String get psetHealthSection => 'System check';

  @override
  String get psetMethodHint => 'The method used for all prayer times';

  @override
  String get psetAdhanOn => 'Adhan on';

  @override
  String get psetAdhanOff => 'Adhan off';

  @override
  String get psetMosque => 'Mosque mode';

  @override
  String get psetMosqueOn => 'Phone silenced automatically at prayer time';

  @override
  String get psetMosqueOff => 'Off — manual only';

  @override
  String get psetDuration => 'Duration';

  @override
  String psetDurationMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get psetQuick => 'Quick enable';

  @override
  String get psetQuick10 => 'Mosque mode — 10 minutes';

  @override
  String get psetQuick20 => 'Mosque mode — 20 minutes';

  @override
  String get psetQuick30 => 'Mosque mode — 30 minutes';

  @override
  String get psetReset => 'Reset';

  @override
  String get psetHealthRun => 'Run system check';

  @override
  String get psetHealthRunning => 'Checking...';

  @override
  String get psetAllGood => 'Everything works perfectly!';

  @override
  String get psetFix => 'Fix';

  @override
  String get psetBadgeHealthy => 'System healthy';

  @override
  String get psetBadgeWarning => 'There are warnings';

  @override
  String get psetBadgeCritical => 'There are critical issues';

  @override
  String get tasbihTitle => 'Electronic tasbih';

  @override
  String get tasbihReset => 'Reset';

  @override
  String get tasbihPreset33 => '33';

  @override
  String get tasbihPreset100 => '100';

  @override
  String get tasbihOpen => 'Open';

  @override
  String get tasbihHint => 'Tap anywhere on screen to count';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get toolsPrayer => 'Prayer times';

  @override
  String get toolsPrayerSub => 'Times & alerts';

  @override
  String get toolsQibla => 'Qibla';

  @override
  String get toolsQiblaSub => 'Qibla direction';

  @override
  String get toolsTasbih => 'Tasbih';

  @override
  String get toolsTasbihSub => 'Dhikr counter';

  @override
  String get toolsSearch => 'Search';

  @override
  String get toolsSearchSub => 'Search Quran & hadith';

  @override
  String get toolsHifz => 'Memorization & review';

  @override
  String get toolsHifzSub => 'Memorize & review verses';

  @override
  String get toolsProfile => 'My profile';

  @override
  String get toolsProfileSub => 'Statistics & progress';

  @override
  String get toolsSettingsSub => 'General & appearance settings';

  @override
  String audioTitle(String name) {
    return 'Surah $name';
  }

  @override
  String get audioResumeTitle => 'Resume recitation?';

  @override
  String audioResumeBody(String surah, int ayah) {
    return 'Continue reciting from surah $surah - verse $ayah?';
  }

  @override
  String get audioNo => 'No';

  @override
  String get audioResume => 'Resume';

  @override
  String audioAyahOf(int ayah, int total) {
    return 'Verse $ayah of $total';
  }

  @override
  String get audioPickSurah => 'Pick a surah';

  @override
  String get audioPickReciter => 'Pick a reciter';

  @override
  String audioLoadError(String error) {
    return 'Failed to load the surah: $error';
  }

  @override
  String get audioNowPlaying => 'Now reciting';

  @override
  String get mushafEmpty => 'Empty page';

  @override
  String mushafError(String error) {
    return 'Error: $error';
  }

  @override
  String mushafJuz(int juz) {
    return 'Juz $juz';
  }

  @override
  String get mushafAppearanceTooltip => 'Appearance';

  @override
  String mushafPageIndicator(int page) {
    return 'Page $page / 604';
  }

  @override
  String get mushafCopy => 'Copy';

  @override
  String get mushafSave => 'Save';

  @override
  String get mushafSaved => 'Bookmark saved';

  @override
  String get mushafShareCopied => 'Copied for sharing';

  @override
  String get mushafTafsirTitle => 'Al-Muyassar tafsir';

  @override
  String get mushafTafsirMissing => 'Tafsir currently unavailable';

  @override
  String get mushafReadMore => 'Read more';

  @override
  String get mushafOpenFull => 'Open full tafsir';

  @override
  String mushafAyahLabel(String name, int ayah) {
    return '$name ($ayah)';
  }

  @override
  String mushafShareTemplate(String verse, String surah, int ayah) {
    return '$verse — Holy Quran (surah $surah, verse $ayah)';
  }

  @override
  String get surahLoadError => 'Failed to load the surah';

  @override
  String surahFallback(int number) {
    return 'Surah $number';
  }

  @override
  String get surahKhushuTooltip => 'Khushu mode';

  @override
  String get surahListenTooltip => 'Listen';

  @override
  String get surahAppearance => 'Reading appearance';

  @override
  String get surahShowTranslation => 'Show translation';

  @override
  String get surahTrLang => 'Translation language:';

  @override
  String get verseTafsir => 'Verse tafsir';

  @override
  String get verseAddHifz => 'Add to memorization';

  @override
  String get verseHifzAdded => 'Verse added to memorization cards';

  @override
  String get verseAddBookmark => 'Add bookmark';

  @override
  String get verseBookmarkSaved => 'Bookmark saved';

  @override
  String get verseShare => 'Share';

  @override
  String get verseShareCopied => 'Verse copied for sharing';

  @override
  String get versePlayAudio => 'Play audio';

  @override
  String get verseCopy => 'Copy verse';

  @override
  String get verseCopied => 'Verse copied';

  @override
  String verseShareTemplate(String verse, int surah, int ayah) {
    return '$verse — Holy Quran (surah $surah, verse $ayah)';
  }

  @override
  String get quranTitle => 'Holy Quran';

  @override
  String quranSurahCount(int count) {
    return '$count surahs';
  }

  @override
  String get quranContinue => 'Continue reading';

  @override
  String quranSurahNumber(String number) {
    return 'Surah no. $number';
  }

  @override
  String get quranNoResults => 'No results';

  @override
  String get quranMushaf => 'Mushaf';

  @override
  String get quranKhatmahPlan => 'Khatmah plan';

  @override
  String get quranTafsir => 'Tafsir';

  @override
  String get quranFilterAll => 'All';

  @override
  String get quranMeccan => 'Makki';

  @override
  String get quranMedinan => 'Madani';

  @override
  String get quranSearchHint => 'Search for a surah...';

  @override
  String quranAyahCount(int count) {
    return '$count verses';
  }

  @override
  String get quranError => 'Something went wrong';

  @override
  String get khatmahTitle => 'Khatmah plan';

  @override
  String get khatmahEmpty => 'No active khatmah';

  @override
  String get khatmahStart => 'Start a new khatmah';

  @override
  String get khatmahSchedule => 'Reading schedule';

  @override
  String get khatmahHistory => 'Your past khatmahs';

  @override
  String get khatmahNoneDone => 'No khatmah completed yet';

  @override
  String get khatmahActive => 'Active';

  @override
  String khatmahPageOfTotal(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get khatmahLastPosition => 'Last position';

  @override
  String khatmahPositionAt(String surah, int ayah) {
    return 'Surah $surah - verse $ayah';
  }

  @override
  String get khatmahResume => 'Resume';

  @override
  String khatmahGoal(String date) {
    return 'Goal: $date';
  }

  @override
  String get khatmahDailyGoal => 'Today\'s goal';

  @override
  String khatmahPagesToday(int read, int need) {
    return '$read / $need pages';
  }

  @override
  String get khatmahGoalDone => 'Well done! Daily goal complete';

  @override
  String khatmahSchedulePages(String pages) {
    return '$pages pages';
  }

  @override
  String khatmahDoneIn(int days) {
    return 'Completed in $days days';
  }

  @override
  String get khatmahNew => 'New khatmah';

  @override
  String get khatmahNameHint => 'Khatmah name (optional)';

  @override
  String get khatmahDuration => 'Duration:';

  @override
  String khatmahDaysOption(int days) {
    return '$days days';
  }

  @override
  String khatmahPerDay(int pages) {
    return 'About $pages pages per day';
  }

  @override
  String get khatmahStartButton => 'Start khatmah';

  @override
  String get tadTitle => 'Tadabbur mihrab';

  @override
  String get tadSaved => 'Your note was saved securely';

  @override
  String tadRef(int surah, int ayah) {
    return 'Surah $surah - verse $ayah';
  }

  @override
  String get tadHint => 'Write your reflections here...';

  @override
  String get tadEncrypted => 'Your notes are encrypted locally';

  @override
  String get tadSave => 'Save';

  @override
  String get tadPrevious => 'Your previous notes';

  @override
  String get tadEmpty => 'No notes yet';

  @override
  String get tadPrivacyTitle => 'Your notes\' privacy';

  @override
  String get tadPrivacy1 => 'Your notes are encrypted locally on your device';

  @override
  String get tadPrivacy2 => 'Never uploaded to any cloud';

  @override
  String get tadPrivacy3 => 'Nobody can read them but you';

  @override
  String get tadPrivacyAes =>
      'Uses AES-256 encryption to protect your thoughts.';

  @override
  String get tadGotIt => 'Got it';

  @override
  String get topicTitle => 'Topic taxonomy';

  @override
  String get topicEmpty => 'No topics yet';

  @override
  String get topicEmptyHint => 'The index builds on the first hadith load';

  @override
  String topicHadithCount(int count) {
    return '$count hadith';
  }

  @override
  String get memTitle => 'Hadith memorization';

  @override
  String get memDueToday => 'Due today';

  @override
  String get memReviewedToday => 'Reviewed today';

  @override
  String get memTotal => 'Total memorized';

  @override
  String get memHintFallback => 'The Prophet said: ...';

  @override
  String get memRemember => 'Recall the hadith...';

  @override
  String get memShowAnswer => 'Tap to reveal the answer';

  @override
  String get memDayFallback => '1 day';

  @override
  String get memDone => 'Well done! Today\'s review is complete';

  @override
  String get memComeBack => 'Come back tomorrow to keep memorizing';

  @override
  String get memBack => 'Back';

  @override
  String get lstatsTitle => 'My statistics';

  @override
  String get lstatsBookmarks => 'Bookmarks';

  @override
  String get lstatsHadithUnit => 'hadith';

  @override
  String get lstatsNotes => 'Notes';

  @override
  String get lstatsNoteUnit => 'notes';

  @override
  String get lstatsQuizzes => 'Quizzes';

  @override
  String lstatsQuizAvg(int score) {
    return '$score% average';
  }

  @override
  String get lstatsMemorize => 'Memorized';

  @override
  String get lstatsCardUnit => 'cards';

  @override
  String get lstatsWeekActivity => 'Week activity';

  @override
  String get lstatsByBooks => 'Bookmarks by book';

  @override
  String get lstatsStreak => 'Day streak';

  @override
  String lstatsLongest(int days) {
    return 'Longest streak: $days days';
  }

  @override
  String lstatsBookSaved(int read) {
    return '$read saved';
  }

  @override
  String hifzStreakLine(String emoji) {
    return '$emoji Practice streak';
  }

  @override
  String hifzDays(int count) {
    return '$count days';
  }

  @override
  String get hifzToMemorize => 'To memorize';

  @override
  String get hifzToReview => 'To review';

  @override
  String hifzStartReview(int count) {
    return 'Start review ($count)';
  }

  @override
  String hifzStartNew(int count) {
    return 'Start memorizing $count new verses';
  }

  @override
  String get hifzEmpty => 'Add verses from a surah page to start memorizing';

  @override
  String hifzMyCards(int count) {
    return 'My cards ($count)';
  }

  @override
  String hifzCardRef(int surah, int ayah) {
    return 'Surah $surah : verse $ayah';
  }

  @override
  String get hifzNew => 'New';

  @override
  String get hifzDueToday => 'Due today';

  @override
  String hifzAfterDays(int days) {
    return 'In $days days';
  }

  @override
  String get hifzRepeat => 'Repeats: ';

  @override
  String get searchHintUnified => 'Search Quran & hadith...';

  @override
  String get searchPrompt => 'Search for a verse or hadith';

  @override
  String get searchBadgeHadith => 'Hadith';

  @override
  String get searchBadgeAdhkar => 'Adhkar';

  @override
  String searchQuranRef(String surah, String verse) {
    return 'Surah $surah : verse $verse';
  }

  @override
  String get searchCopied => 'Text copied';

  @override
  String get hsearchTitle => 'Advanced search';

  @override
  String get hsearchAllBooks => 'All books';

  @override
  String get hsearchButton => 'Search';

  @override
  String get hsearchEmpty => 'Search the nine books';

  @override
  String get hsearchEmptySub => 'Search covers Arabic and English text';

  @override
  String get hsearchNoResults => 'No results found';

  @override
  String hsearchCount(int count) {
    return '$count results';
  }

  @override
  String get hsearchByText => 'Text search';

  @override
  String get hsearchByNarrator => 'Narrator search';

  @override
  String get hsearchTextHint => 'Search by word or phrase...';

  @override
  String get hsearchNarratorHint => 'Narrator name in English...';

  @override
  String hsearchHadithNumber(int id) {
    return 'Hadith no. $id';
  }

  @override
  String get hsessionDoneTitle => 'Masha Allah!';

  @override
  String get hsessionDoneBody =>
      'Session complete. Keep practicing daily to retain memorization.';

  @override
  String get hsessionFinish => 'Finish';

  @override
  String hsessionCounter(int index, int total) {
    return 'Memorization session ($index/$total)';
  }

  @override
  String hsessionCardRef(int surah, int ayah) {
    return 'Surah $surah — verse $ayah';
  }

  @override
  String hsessionRepeatCount(int count) {
    return 'Repeats x$count';
  }

  @override
  String get hsessionRatePrompt => 'How was your recall?';

  @override
  String hsessionIntervalDays(int days) {
    return '$days days';
  }

  @override
  String get hpageTitle => 'Jawami al-Kalim';

  @override
  String get hpageSubtitle => 'Library of the noble Prophetic Sunnah';

  @override
  String get hpageBookmarksTooltip => 'Bookmarks';

  @override
  String get hpageQuizTooltip => 'Hadith quiz';

  @override
  String get hpageBooks => 'Books & collections';

  @override
  String get hpageBooksHint => 'Pick a book to browse hadith';

  @override
  String get hpageBookCollection => 'Hadith collection';

  @override
  String hpageError(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get hpageStudyTools => 'Study tools';

  @override
  String get hpageToolMemorize => 'Spaced memorization';

  @override
  String get hpageToolStats => 'Statistics';

  @override
  String get hpageToolTags => 'Tags';

  @override
  String get hpageToolTopics => 'Topic tree';

  @override
  String get hpageToolAdvanced => 'Advanced browser';

  @override
  String get hpageContinue => 'Continue reading';

  @override
  String hpageContinueAt(String title, int index, int total) {
    return '$title - hadith $index / $total';
  }

  @override
  String get hpageToday => 'Hadith of the day';

  @override
  String get hpageReadMore => 'Read more';

  @override
  String get hbmRemoved => 'Hadith removed from bookmarks';

  @override
  String get hbmEmpty => 'No bookmarked hadith';

  @override
  String get hbmEmptyHint => 'Tap the bookmark icon while reading a hadith';

  @override
  String get tagsNew => 'Create new tag';

  @override
  String get tagsNameHint => 'Tag name (e.g. for review)';

  @override
  String get tagsIcon => 'Icon';

  @override
  String get tagsColor => 'Color';

  @override
  String get tagsCreate => 'Create';

  @override
  String get tagsTitle => 'My tags';

  @override
  String get tagsEmpty => 'No tags yet';

  @override
  String get tagsEmptyHint => 'Create tags to organize your favorite hadith';

  @override
  String get tagsNewFab => 'New tag';

  @override
  String get tagsRemoved => 'Hadith removed from tag';

  @override
  String get tagsAdded => 'Hadith added to tag';

  @override
  String get cmpTitle => 'Narration comparison';

  @override
  String get cmpDiffTooltip => 'Show differences';

  @override
  String get cmpSideBySide => 'Side-by-side view';

  @override
  String get cmpEmpty => 'No matching narrations found';

  @override
  String get cmpEmptyHint => 'Try a different keyword';

  @override
  String get cmpUngraded => 'Ungraded';

  @override
  String cmpDiffCount(int count) {
    return '$count differences';
  }

  @override
  String get cmpSideTitle => 'Side-by-side comparison';

  @override
  String get quizComplete => 'Complete the hadith';

  @override
  String get quizChoose => 'Choose correctly';

  @override
  String get quizNarrator => 'Identify the narrator';

  @override
  String get quizGrade => 'Hadith grade';

  @override
  String quizQuestion(int index, int total) {
    return 'Question $index of $total';
  }

  @override
  String get quizPassed => 'Well done!';

  @override
  String get quizFailed => 'Try again';

  @override
  String quizScore(int score, int total) {
    return '$score of $total correct answers';
  }

  @override
  String get quizRetry => 'Retake quiz';

  @override
  String get hchLoading => 'Loading chapters...';

  @override
  String get hchError => 'Failed to load the book';

  @override
  String hchChapters(int count) {
    return '$count chapters';
  }

  @override
  String get hchAllTitle => 'All hadith';

  @override
  String get hchViewAll => 'View all hadith';

  @override
  String get hchSection => 'Chapters';

  @override
  String get hchHadithUnit => 'hadith';

  @override
  String get hchEmpty => 'No hadith in this chapter';

  @override
  String get igTitle => 'Isnad graph';

  @override
  String igCount(int count) {
    return '$count narrators';
  }

  @override
  String get igLoading => 'Analyzing the isnad...';

  @override
  String get igEmpty => 'No isnad found';

  @override
  String get ichainTitle => 'Isnad chain';

  @override
  String get ichainGraphTooltip => 'Graph view';

  @override
  String get ichainLoading => 'Analyzing the isnad chain...';

  @override
  String get ichainEmptyHint =>
      'This hadith text has no analyzable isnad chain';

  @override
  String ichainCount(int count) {
    return '$count narrators in the chain';
  }

  @override
  String get ichainCardTitle => 'Narrator card';

  @override
  String get hreaderBookmarked => 'Hadith added to bookmarks';

  @override
  String get hreaderCopied => 'Hadith copied';

  @override
  String hreaderCopyTemplate(
    String text,
    String title,
    int id,
    String narrator,
  ) {
    return '$text\n\n$narrator\n\n— $title #$id';
  }

  @override
  String hreaderTitle(String title, int id) {
    return '$title — #$id';
  }

  @override
  String get hreaderSharahTooltip => 'Commentary';

  @override
  String hreaderNumberBadge(int id) {
    return 'Hadith #$id';
  }

  @override
  String get hreaderPrev => 'Previous';

  @override
  String get hreaderNext => 'Next';

  @override
  String get hshareTitle => 'Share as image';

  @override
  String get hshareNow => 'Share now';

  @override
  String get hshareProcessing => 'Preparing...';

  @override
  String hshareText(String title, int id) {
    return '$title - hadith no. $id\n\nNoor Islamic app';
  }

  @override
  String hshareError(String error) {
    return 'Failed to save the image: $error';
  }

  @override
  String get schTitle => 'Student-of-knowledge mode';

  @override
  String get schHighlightTooltip => 'Highlight key words';

  @override
  String get schShareTooltip => 'Share with documentation';

  @override
  String get schUngraded => 'Ungraded';

  @override
  String schHadithNumber(int number) {
    return 'Hadith no. $number';
  }

  @override
  String get schTakhrij => 'Documentation';

  @override
  String get schBook => 'Book';

  @override
  String get schChapter => 'Chapter';

  @override
  String schChapterValue(int chapter) {
    return 'Chapter $chapter';
  }

  @override
  String get schNumber => 'Hadith number';

  @override
  String get schCompanion => 'Companion';

  @override
  String get schTopics => 'Topics';

  @override
  String get schNotes => 'My notes';

  @override
  String get schNotesHint => 'Add your notes on this hadith...';

  @override
  String get schNotesSaved => 'Notes save automatically';

  @override
  String get schSimilar => 'Similar hadith';

  @override
  String get schNoSimilar => 'No similar hadith';

  @override
  String get schNoIsnad => 'No isnad found in this hadith';

  @override
  String get schIsnadAnalysis => 'Isnad analysis';

  @override
  String schChainCount(int count) {
    return '$count narrators in the chain';
  }

  @override
  String get schStatNarrators => 'Narrators';

  @override
  String get schStatCompanions => 'Companions';

  @override
  String get schStatProphet => 'The Prophet';

  @override
  String schChainConnected(int count) {
    return 'Connected chain ($count links)';
  }

  @override
  String schChainShort(int count) {
    return 'Short chain ($count links)';
  }

  @override
  String get schCopyTakhrij => 'Copy with documentation';

  @override
  String get schSaveReview => 'Save for review';

  @override
  String get schCopiedTakhrij => 'Copied with documentation';

  @override
  String get schAddedReview => 'Added to review';

  @override
  String schTakhrijBook(String book) {
    return 'Book: $book';
  }

  @override
  String schTakhrijChapter(int chapter, int number) {
    return 'Chapter $chapter - hadith $number';
  }

  @override
  String schTakhrijGrade(String grade) {
    return 'Grade: $grade';
  }

  @override
  String schTakhrijCompanion(String companion) {
    return 'Companion: $companion';
  }

  @override
  String get schTakhrijApp => '— Noor Islamic app';

  @override
  String get advTabSearch => 'Search';

  @override
  String get advTabCompanions => 'Companions';

  @override
  String get advTabTopics => 'Topics';

  @override
  String get advTabBooks => 'Books';

  @override
  String get advSearchHint => 'Type text to search...';

  @override
  String get advScope => 'Search scope:';

  @override
  String get advFilterMatn => 'Text';

  @override
  String get advFilterSanad => 'Chain';

  @override
  String get advFilterBooks => 'Filter by books';

  @override
  String get advMode => 'Search mode:';

  @override
  String get advModeSmart => 'Smart';

  @override
  String get advModeAny => 'Any word';

  @override
  String get advModeAll => 'All words';

  @override
  String get advModePhrase => 'Phrase';

  @override
  String get advModeRoot => 'By root';

  @override
  String get advNarratorHint => 'A narrator in the chain...';

  @override
  String get advFromHint => 'From';

  @override
  String get advToHint => 'To';

  @override
  String get advGrade => 'Grade:';

  @override
  String get advEmptyTitle => 'Hadith encyclopedia';

  @override
  String get advEmptyBody =>
      'Search thousands of Prophetic hadith from the nine canonical books';

  @override
  String get advAllBooksOption => 'All books';

  @override
  String advRangeBoth(int from, int to) {
    return 'No. $from - $to';
  }

  @override
  String advRangeFrom(int from) {
    return 'No. from $from';
  }

  @override
  String advRangeTo(int to) {
    return 'No. to $to';
  }

  @override
  String advMatchScore(String score) {
    return '$score% match';
  }

  @override
  String advBookNumber(String book, int number) {
    return '$book - $number';
  }

  @override
  String get layScholarTooltip => 'Scholar mode';

  @override
  String get layTabMatn => 'Text';

  @override
  String get layTabSanad => 'Chain';

  @override
  String get layTabHukm => 'Ruling';

  @override
  String get layCopyMatn => 'Copy text';

  @override
  String get layChainTitle => 'Narrator chain';

  @override
  String get layFullSanad => 'Full chain';

  @override
  String get layCompanionRaa => 'A noble Companion';

  @override
  String get layGradeGuide => 'Rulings guide';

  @override
  String layChapterOf(int chapter) {
    return 'Chapter $chapter';
  }

  @override
  String layHadithOf(int number) {
    return 'Hadith no. $number';
  }

  @override
  String get layOtherBooks => 'This hadith in other books';

  @override
  String get layNotInOthers => 'Not found in other books';

  @override
  String laySimilarNumber(int number) {
    return 'Hadith $number';
  }

  @override
  String get layCopyTakhrij => 'Copy full documentation';

  @override
  String get layCopied => 'Copied';

  @override
  String layTakhrijNumber(int number) {
    return 'Hadith no. $number';
  }

  @override
  String layTakhrijChapter(int chapter) {
    return 'Chapter $chapter';
  }

  @override
  String layTakhrijGrade(String grade) {
    return 'Grade: $grade';
  }

  @override
  String layTakhrijCompanion(String companion) {
    return 'Companion: $companion';
  }

  @override
  String sharhTitle(int id) {
    return 'Hadith commentary #$id';
  }

  @override
  String get sharhMatn => 'Hadith text';

  @override
  String get sharhTakhrij => 'Documentation & grade';

  @override
  String get sharhBook => 'Book';

  @override
  String get sharhNumber => 'Hadith number';

  @override
  String get sharhNarrator => 'Narrator';

  @override
  String get sharhSource => 'Source';

  @override
  String get sharhBenefits => 'Hadith benefits';

  @override
  String get sharhNotes => 'My notes';

  @override
  String get sharhNotesHint => 'Write your notes and reflections here...';

  @override
  String get sharhNoteSaved => 'Note saved';

  @override
  String get sharhSimilar => 'Similar hadith';

  @override
  String get sharhTools => 'Study tools';

  @override
  String get sharhIsnadMap => 'Isnad map';

  @override
  String get sharhIsnadMapSub => 'Hadith narrator chain';

  @override
  String get sharhIsnadGraphSub => 'Interactive narrator-chain view';

  @override
  String get sharhCompare => 'Compare narrations';

  @override
  String get sharhCompareSub => 'Different wordings across books';

  @override
  String get sharhAddTag => 'Add to a tag';

  @override
  String get sharhAddTagSub => 'Organize hadith in your lists';

  @override
  String get adhkarTitle => 'Daily adhkar';

  @override
  String adhkarStreakDays(int count) {
    return '$count days';
  }

  @override
  String get adhkarMorning => 'Morning adhkar';

  @override
  String get adhkarEvening => 'Evening adhkar';

  @override
  String get adhkarAfterPrayer => 'After prayer';

  @override
  String get adhkarSleep => 'Sleep adhkar';

  @override
  String get adhkarWakeup => 'Waking up';

  @override
  String get adhkarQuranic => 'Quranic duas';

  @override
  String get adhkarLibrary => 'Adhkar library';

  @override
  String get adhkarLibrarySub => '100+ sourced adhkar';

  @override
  String get adhkarUnitZekr => 'adhkar';

  @override
  String get adhkarUnitDua => 'duas';

  @override
  String get adhkarTodayDone => 'Well done! Today\'s portion complete';

  @override
  String get adhkarToday => 'Today\'s portion';

  @override
  String get adhkarChipMorning => 'Morning';

  @override
  String get adhkarChipEvening => 'Evening';

  @override
  String get adhkarBlessed => 'May God bless you';

  @override
  String adhkarRemainingJoined(String list) {
    return 'Remaining: $list';
  }

  @override
  String get adhkarAllDone => 'Today\'s adhkar complete!';

  @override
  String adhkarCongratsBody(String name) {
    return 'You completed $name';
  }

  @override
  String get adhkarDone => 'Done';

  @override
  String get adhkarNoAdhkar => 'No adhkar';

  @override
  String get adhkarBlessAccept => 'May God bless and accept from you';

  @override
  String get adhkarBackToList => 'Back to list';

  @override
  String adhkarOfTotal(int total) {
    return 'of $total';
  }

  @override
  String get tafsirPickTooltip => 'Pick a tafsir';

  @override
  String get tafsirTabBookmarks => 'Bookmarks';

  @override
  String get tafsirTabHistory => 'History';

  @override
  String get tafsirSurahLabel => 'Surah';

  @override
  String get tafsirNoTafsir => 'No tafsir for this surah';

  @override
  String get tafsirNoBookmarks => 'No saved bookmarks';

  @override
  String tafsirBookmarkRef(String name, int ayah) {
    return 'Surah $name - verse $ayah';
  }

  @override
  String get tafsirNoHistory => 'No reading history';

  @override
  String tafsirAyahBadge(int ayah) {
    return 'Verse $ayah';
  }

  @override
  String get tafsirSearchHint => 'Search tafsir (root, word, or topic)...';

  @override
  String get tafsirMinChars => 'Enter at least 3 letters for accurate search';

  @override
  String get tafsirNoSearchResults => 'No matching results in this tafsir';

  @override
  String get tafsirTopicsTitle => 'Topics (Thematic Index)';

  @override
  String get tafsirTipsTitle => 'Search tips:';

  @override
  String get tafsirTipRoot => 'Search by word root for broader results.';

  @override
  String get tafsirTipScope =>
      'Search matches text within the currently selected tafsir only.';

  @override
  String tafsirResultRef(int surah, int ayah) {
    return 'Surah $surah - verse $ayah';
  }

  @override
  String tafsirMinutesAgo(int minutes) {
    return '$minutes minutes ago';
  }

  @override
  String tafsirHoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String tafsirDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get tfwLoadError => 'Failed to load tafsir';

  @override
  String get tfwNoAyahTafsir => 'No tafsir for this verse';

  @override
  String get tfwFullView => 'Full view';

  @override
  String get tfwCompare => 'Compare';

  @override
  String get tfwNoTafsir => 'No tafsir';

  @override
  String tfwSurahOf(int surah) {
    return 'Surah $surah';
  }

  @override
  String get tfwCompareTitle => 'Compare tafsirs';

  @override
  String tfwSheetRef(int surah, int ayah) {
    return 'Surah $surah - verse $ayah';
  }

  @override
  String get proTodayStats => 'Today\'s statistics';

  @override
  String get proVersesRead => 'Verses read';

  @override
  String get proReadingTime => 'Reading time';

  @override
  String get proToday => 'Today';

  @override
  String get proListening => 'Listening';

  @override
  String get proListeningToday => 'Today\'s verses';

  @override
  String get proAdhkarStreak => 'Adhkar streak';

  @override
  String get proDayOne => 'day';

  @override
  String get proDays => 'days';

  @override
  String get proAdhkarToday => 'Today\'s adhkar';

  @override
  String get proAfterPrayer => 'After prayer';

  @override
  String get proKhatmah => 'Khatmah progress';

  @override
  String proKhatmahAt(int surah, int ayah) {
    return 'Surah $surah — verse $ayah';
  }

  @override
  String proKhatmahDone(int count) {
    return '$count completed khatmahs';
  }

  @override
  String get proWeek => 'Week summary';

  @override
  String get proListenTime => 'Listening time';

  @override
  String get proFullAdhkarDays => 'Full adhkar days';

  @override
  String get proTotal => 'All-time statistics';

  @override
  String get proVerseUnit => 'verses';

  @override
  String get proReadUnit => 'reading';

  @override
  String get proKhatmahUnit => 'khatmahs';

  @override
  String proSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String proMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String proHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get qiblaPermWarning =>
      'Please enable location permission from settings';

  @override
  String get qiblaFallbackWarning =>
      'Couldn\'t locate you; showing the direction from Riyadh';

  @override
  String get qiblaTimeoutTitle => 'Save power';

  @override
  String get qiblaTimeoutBody => 'Keep locating the qibla?';

  @override
  String get qiblaClose => 'Close';

  @override
  String get qiblaContinue => 'Continue';

  @override
  String get qiblaLockedSnack => 'Qibla direction pinned';

  @override
  String get qiblaUnlockedSnack => 'Pin removed';

  @override
  String get qiblaCalibTitle => 'Calibrate the compass';

  @override
  String get qiblaCalibHint => 'To improve compass accuracy:';

  @override
  String get qiblaCalib1 => '1. Move the phone away from metal';

  @override
  String get qiblaCalib2 => '2. Move the phone in a figure 8';

  @override
  String get qiblaCalib3 => '3. Repeat until accuracy improves';

  @override
  String get qiblaTitle => 'Qibla direction';

  @override
  String get qiblaLocating => 'Locating you...';

  @override
  String get qiblaLockedBadge => 'Pinned direction';

  @override
  String get qiblaPinned => 'Pinned';

  @override
  String get qiblaCalibNeeded => 'Calibration needed';

  @override
  String get qiblaKaaba => 'Kaaba';

  @override
  String get qiblaDirection => 'Qibla direction';

  @override
  String get qiblaDistance => 'Distance';

  @override
  String get qiblaBearing => 'Bearing';

  @override
  String get qiblaLock => 'Pin';

  @override
  String get qiblaUnlock => 'Unpin';

  @override
  String get obSkip => 'Skip';

  @override
  String get obNext => 'Next';

  @override
  String get obStart => 'Start now';

  @override
  String get ob1Title => 'Welcome to Noor';

  @override
  String get ob1Subtitle => 'A complete digital worship space';

  @override
  String get ob1Desc =>
      'Quran recitation, hadith memorization, prayer times, and adhkar in one place';

  @override
  String get ob2Title => 'Holy Quran';

  @override
  String get ob2Subtitle => 'Recite and reflect';

  @override
  String get ob2Desc => 'Uthmani-script reading, tafsir, and multiple reciters';

  @override
  String get ob3Title => 'Prophetic hadith';

  @override
  String get ob3Subtitle => 'The nine books';

  @override
  String get ob3Desc =>
      'Advanced search, topic tree, documentation, and spaced memorization';

  @override
  String get ob4Title => 'Prayer times';

  @override
  String get ob4Subtitle => 'Accurate and smart';

  @override
  String get ob4Desc => 'Prayer alerts, automatic silent mode, and the qibla';

  @override
  String get ob5Title => 'Are you ready?';

  @override
  String get ob5Subtitle => 'Begin your spiritual journey';

  @override
  String get ob5Desc =>
      'We ask God to make this app beneficial for your faith and life';

  @override
  String get npcBadge => 'Next prayer';

  @override
  String get npcLoading => 'Loading...';

  @override
  String npcAfter(String remaining) {
    return 'In $remaining';
  }

  @override
  String get npcInshallah => 'God willing';

  @override
  String get alibTitle => 'Adhkar library';

  @override
  String get alibReviewBanner => 'Library content under scholarly review';

  @override
  String alibCount(int count) {
    return '$count adhkar';
  }

  @override
  String alibSource(String ref) {
    return 'Source: $ref';
  }

  @override
  String get favAdhkar => 'Adhkar';

  @override
  String get continueStart => 'Start reading';

  @override
  String get continueSaved => 'Saved';

  @override
  String continueAyah(int ayah) {
    return 'Verse $ayah';
  }

  @override
  String get continueGo => 'Tap to open the mushaf';

  @override
  String dayTasks(int done) {
    return '$done/5 prayers';
  }

  @override
  String dayStreak(int streak) {
    return '$streak day streak';
  }

  @override
  String get adhkarCardDone => 'Today\'s portion complete';

  @override
  String get adhkarCardTodo => 'Keep remembering God';

  @override
  String adhkarCardPct(int pct) {
    return '$pct% complete';
  }

  @override
  String get sugTipTitle => 'Smart tip now:';

  @override
  String get tfwPreviewText => 'Text preview';

  @override
  String get npcTomorrow => 'Tomorrow';

  @override
  String get a11yPrevious => 'Previous';

  @override
  String get a11yNext => 'Next';

  @override
  String a11yQiblaCompass(String qibla, String heading) {
    return 'Qibla direction $qibla degrees, device heading $heading degrees';
  }

  @override
  String a11yTasbihCount(int count) {
    return 'Count: $count';
  }
}

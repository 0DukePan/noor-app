import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// The app name shown in the title bar and launcher context.
  ///
  /// In en, this message translates to:
  /// **'Noor'**
  String get appTitle;

  /// Bottom navigation label for the home dashboard tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label for the Quran tab.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get navQuran;

  /// Bottom navigation label for the Hadith tab.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get navHadith;

  /// Bottom navigation label for the Adhkar tab.
  ///
  /// In en, this message translates to:
  /// **'Adhkar'**
  String get navAdhkar;

  /// Bottom navigation label for the Tools tab.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get navTools;

  /// Shown on the one-time first-launch import screen.
  ///
  /// In en, this message translates to:
  /// **'Preparing the hadith database...'**
  String get dbImportTitle;

  /// Explains the one-time first-launch database import.
  ///
  /// In en, this message translates to:
  /// **'The first launch imports the hadith collections. This happens only once.'**
  String get dbImportSubtitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'A comprehensive Islamic app serving as a digital worship environment'**
  String get appTagline;

  /// Generic retry button label used on error states.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Home page error state when dashboard data fails to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data'**
  String get homeLoadError;

  /// Home section header for the continue-reading card.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get homeContinueReading;

  /// Home section header for the favorites strip.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get homeFavorites;

  /// Home section header for today's adhkar status.
  ///
  /// In en, this message translates to:
  /// **'Today\'s adhkar'**
  String get homeTodayAdhkar;

  /// Home section header for the hadith-of-the-day card.
  ///
  /// In en, this message translates to:
  /// **'Prophetic light'**
  String get homePropheticLight;

  /// Settings page app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings page header title.
  ///
  /// In en, this message translates to:
  /// **'Customize the app'**
  String get settingsHeader;

  /// Settings page header subtitle.
  ///
  /// In en, this message translates to:
  /// **'Make the app fit your needs'**
  String get settingsHeaderSubtitle;

  /// Settings section header for theme mode.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Light theme chip label.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Dark theme chip label.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Follow-system theme chip label.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Settings section header for reading display options.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get settingsReading;

  /// Font-size slider label.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get settingsFontSize;

  /// Settings section header for general toggles.
  ///
  /// In en, this message translates to:
  /// **'General settings'**
  String get settingsGeneral;

  /// Haptic feedback toggle title.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingsHaptics;

  /// Haptic feedback toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tactile feedback on interaction'**
  String get settingsHapticsSubtitle;

  /// Clear-cache row title.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCache;

  /// Clear-cache row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete temporary data to free space'**
  String get settingsClearCacheSubtitle;

  /// Settings section header for advanced navigation rows.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get settingsAdvanced;

  /// Notifications settings row title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Notifications settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Morning/evening adhkar, prayer alerts'**
  String get settingsNotificationsSubtitle;

  /// Storage settings row title.
  ///
  /// In en, this message translates to:
  /// **'Storage & performance'**
  String get settingsStorage;

  /// Storage settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage stored data'**
  String get settingsStorageSubtitle;

  /// Privacy sheet entry title.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settingsPrivacy;

  /// Privacy sheet entry subtitle.
  ///
  /// In en, this message translates to:
  /// **'We collect no personal data'**
  String get settingsPrivacySubtitle;

  /// About row title.
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get settingsAbout;

  /// App name in the about sheet.
  ///
  /// In en, this message translates to:
  /// **'Noor'**
  String get settingsAppName;

  /// About sheet description.
  ///
  /// In en, this message translates to:
  /// **'A comprehensive Islamic app — Quran, hadith, prayer times, adhkar and tafsir'**
  String get settingsAboutBody;

  /// Version footer with the version string.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsAppVersion(String version);

  /// Privacy sheet row: offline-first.
  ///
  /// In en, this message translates to:
  /// **'The app works offline for core content (Quran, hadith, tafsir, adhkar).'**
  String get settingsPrivacyRowOffline;

  /// Privacy sheet row: no tracking.
  ///
  /// In en, this message translates to:
  /// **'No trackers; anonymous usage statistics are off by default and only collected if you enable them. Your data is never shared with any third party.'**
  String get settingsPrivacyRowTracking;

  /// Privacy sheet row: location use.
  ///
  /// In en, this message translates to:
  /// **'Your location is used on-device only to compute prayer times and the qibla; it is never sent to any server.'**
  String get settingsPrivacyRowLocation;

  /// Privacy sheet row: crash reports.
  ///
  /// In en, this message translates to:
  /// **'Only on a technical crash, error data goes to Sentry with no personally identifying information.'**
  String get settingsPrivacyRowCrash;

  /// Privacy sheet row: encrypted notes.
  ///
  /// In en, this message translates to:
  /// **'Your personal notes (tadabbur mihrab) are encrypted and kept on your device only.'**
  String get settingsPrivacyRowNotes;

  /// Privacy sheet row: local-only.
  ///
  /// In en, this message translates to:
  /// **'No cloud sync: all your data (bookmarks, statistics, progress) stays on your device.'**
  String get settingsPrivacyRowSync;

  /// Privacy sheet row: rare network fetches.
  ///
  /// In en, this message translates to:
  /// **'The app may contact public servers only to fetch missing data (tafsir/recitation/times) without sending any of your data.'**
  String get settingsPrivacyRowNetwork;

  /// Clear-cache dialog title.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCacheTitle;

  /// Clear-cache dialog body.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? The downloaded recitation cache and search index will be deleted and rebuilt automatically when needed.'**
  String get settingsClearCacheBody;

  /// Generic cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// Confirm-clear button.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClear;

  /// Snackbar after clearing the cache.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get settingsCacheCleared;

  /// Settings toggle title for the anonymous usage statistics opt-in.
  ///
  /// In en, this message translates to:
  /// **'Usage statistics'**
  String get settingsAnalytics;

  /// Subtitle when usage statistics are disabled (the default).
  ///
  /// In en, this message translates to:
  /// **'Off by default — anonymous counts stay on your device'**
  String get settingsAnalyticsOff;

  /// Subtitle when usage statistics are enabled.
  ///
  /// In en, this message translates to:
  /// **'On — anonymous usage counts are collected'**
  String get settingsAnalyticsOn;

  /// Privacy sheet row describing the opt-in anonymous statistics.
  ///
  /// In en, this message translates to:
  /// **'Anonymous usage statistics: off by default; if you enable them, only aggregate counts are collected — never your identity or content.'**
  String get settingsAnalyticsPrivacy;

  /// Notification settings app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// Adhkar reminders section header.
  ///
  /// In en, this message translates to:
  /// **'Adhkar reminders'**
  String get notifAdhkarSection;

  /// Morning adhkar toggle title.
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar'**
  String get notifMorning;

  /// Morning adhkar toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'30 minutes after Fajr'**
  String get notifMorningSubtitle;

  /// Evening adhkar toggle title.
  ///
  /// In en, this message translates to:
  /// **'Evening adhkar'**
  String get notifEvening;

  /// Evening adhkar toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'30 minutes before Maghrib'**
  String get notifEveningSubtitle;

  /// Prayer notifications section header.
  ///
  /// In en, this message translates to:
  /// **'Prayer notifications'**
  String get notifPrayerSection;

  /// Pre-prayer alert toggle title.
  ///
  /// In en, this message translates to:
  /// **'Pre-prayer alert'**
  String get notifBeforePrayer;

  /// Pre-prayer subtitle with the lead minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before'**
  String notifBeforeMinutes(int minutes);

  /// Lead-time row label.
  ///
  /// In en, this message translates to:
  /// **'Before prayer by'**
  String get notifBeforeLabel;

  /// Compact minutes label for the slider.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String notifMinutesShort(int minutes);

  /// Daily reading reminder section header.
  ///
  /// In en, this message translates to:
  /// **'Daily reading reminder'**
  String get notifDailySection;

  /// Daily khatmah toggle title.
  ///
  /// In en, this message translates to:
  /// **'Daily khatmah reminder'**
  String get notifKhatmah;

  /// Khatmah reminder time subtitle.
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String notifAtTime(String time);

  /// Disabled-state subtitle for reminder toggles.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifDisabled;

  /// Reminder time row label.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get notifReminderTime;

  /// Quiet hours section header.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notifQuietSection;

  /// Quiet hours toggle title.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notifQuiet;

  /// Quiet hours active-range subtitle.
  ///
  /// In en, this message translates to:
  /// **'From {start}:00 to {end}:00'**
  String notifQuietRange(int start, int end);

  /// Apply notification settings button.
  ///
  /// In en, this message translates to:
  /// **'Apply settings'**
  String get notifApply;

  /// Snackbar after applying notification settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications updated'**
  String get notifUpdated;

  /// Scheduled khatmah reminder message.
  ///
  /// In en, this message translates to:
  /// **'Time for your daily reading portion'**
  String get notifKhatmahMessage;

  /// Storage settings app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Storage & performance'**
  String get storageTitle;

  /// Cache stats section header.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get storageCacheSection;

  /// Cache actions section header.
  ///
  /// In en, this message translates to:
  /// **'Manage data'**
  String get storageManageSection;

  /// Silent-UI section header.
  ///
  /// In en, this message translates to:
  /// **'Quiet interface'**
  String get storageSilentSection;

  /// Cached surahs stat label.
  ///
  /// In en, this message translates to:
  /// **'Saved surahs'**
  String get storageSurahs;

  /// Cached hadiths stat label.
  ///
  /// In en, this message translates to:
  /// **'Saved hadiths'**
  String get storageHadiths;

  /// Cached adhkar stat label.
  ///
  /// In en, this message translates to:
  /// **'Saved adhkar'**
  String get storageAdhkar;

  /// Clear-cache action title.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get storageClearTitle;

  /// Clear-cache action subtitle.
  ///
  /// In en, this message translates to:
  /// **'Reload data from source'**
  String get storageClearSubtitle;

  /// Refresh-stats action title.
  ///
  /// In en, this message translates to:
  /// **'Refresh statistics'**
  String get storageRefreshTitle;

  /// Refresh-stats action subtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-read displayed data'**
  String get storageRefreshSubtitle;

  /// Silent-UI explainer paragraph.
  ///
  /// In en, this message translates to:
  /// **'Noor uses a quiet interface with no annoying popups. All notifications appear gently and disappear automatically.'**
  String get storageSilentBody;

  /// Gentle-notification preview button.
  ///
  /// In en, this message translates to:
  /// **'Preview gentle notification'**
  String get storagePreviewGentle;

  /// Success-notification preview button.
  ///
  /// In en, this message translates to:
  /// **'Preview success notification'**
  String get storagePreviewSuccess;

  /// Sample gentle notification message.
  ///
  /// In en, this message translates to:
  /// **'This is a gentle notification sample'**
  String get storageGentleSample;

  /// Sample success notification message.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully!'**
  String get storageSavedOk;

  /// Toast after clearing storage.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get storageCacheCleared;

  /// Toast after refreshing statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics updated'**
  String get storageStatsUpdated;

  /// Qada tracker app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Qada tracker'**
  String get qadaTitle;

  /// Qada prayers tab.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get qadaTabPrayer;

  /// Qada fasting tab.
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get qadaTabFast;

  /// Qada completion dialog title.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get qadaCongrats;

  /// Qada completion dialog body.
  ///
  /// In en, this message translates to:
  /// **'You have completed this record'**
  String get qadaCongratsBody;

  /// Qada completion dialog button.
  ///
  /// In en, this message translates to:
  /// **'Praise be to God'**
  String get qadaPraiseGod;

  /// Empty state for the prayers tab.
  ///
  /// In en, this message translates to:
  /// **'No missed prayers to make up'**
  String get qadaEmptyPrayer;

  /// Empty state for the fasting tab.
  ///
  /// In en, this message translates to:
  /// **'No fasting days to make up'**
  String get qadaEmptyFast;

  /// Add-record button.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get qadaAdd;

  /// Add-record button under the list.
  ///
  /// In en, this message translates to:
  /// **'Add new record'**
  String get qadaAddNew;

  /// Record progress fraction.
  ///
  /// In en, this message translates to:
  /// **'Done: {done} of {total}'**
  String qadaProgress(int done, int total);

  /// Completed-record badge.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get qadaComplete;

  /// Remaining prayers count.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {remaining} prayers'**
  String qadaRemainingPrayer(int remaining);

  /// Remaining fasting days count.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {remaining} days'**
  String qadaRemainingFast(int remaining);

  /// Log-one-prayer button.
  ///
  /// In en, this message translates to:
  /// **'I made up one prayer'**
  String get qadaDidPrayer;

  /// Log-one-fast button.
  ///
  /// In en, this message translates to:
  /// **'I fasted one day'**
  String get qadaDidFast;

  /// Add-dialog title for prayers.
  ///
  /// In en, this message translates to:
  /// **'Add prayers to make up'**
  String get qadaAddPrayerTitle;

  /// Add-dialog title for fasting.
  ///
  /// In en, this message translates to:
  /// **'Add fasting days to make up'**
  String get qadaAddFastTitle;

  /// Record name field label.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get qadaNameLabel;

  /// Record name field hint.
  ///
  /// In en, this message translates to:
  /// **'E.g. 2020 prayers'**
  String get qadaNameHint;

  /// Record count field label.
  ///
  /// In en, this message translates to:
  /// **'Count *'**
  String get qadaCountLabel;

  /// Prayer count field hint.
  ///
  /// In en, this message translates to:
  /// **'Number of prayers'**
  String get qadaCountPrayerHint;

  /// Fasting count field hint.
  ///
  /// In en, this message translates to:
  /// **'Number of days'**
  String get qadaCountFastHint;

  /// Record notes field label.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get qadaNotesLabel;

  /// Record notes field hint.
  ///
  /// In en, this message translates to:
  /// **'Any extra notes'**
  String get qadaNotesHint;

  /// Invalid-count snackbar.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid count'**
  String get qadaInvalidCount;

  /// Default prayer record name.
  ///
  /// In en, this message translates to:
  /// **'Qada prayers'**
  String get qadaDefaultPrayerName;

  /// Default fasting record name.
  ///
  /// In en, this message translates to:
  /// **'Fasting days'**
  String get qadaDefaultFastName;

  /// Prayer page app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get prayerTitle;

  /// Qada navigation button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Missed prayers'**
  String get prayerQadaTooltip;

  /// Prayer page error state.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load prayer times'**
  String get prayerLoadError;

  /// Shown when no prayers remain today.
  ///
  /// In en, this message translates to:
  /// **'Today\'s prayers are done'**
  String get prayerDayDone;

  /// Next-prayer countdown header.
  ///
  /// In en, this message translates to:
  /// **'Next prayer: {name}'**
  String prayerNext(String name);

  /// Countdown caption.
  ///
  /// In en, this message translates to:
  /// **'Time until adhan'**
  String get prayerUntilAdhan;

  /// Prayer settings app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Prayer settings'**
  String get psetTitle;

  /// Adhan section header.
  ///
  /// In en, this message translates to:
  /// **'Adhan & alerts'**
  String get psetAdhanSection;

  /// Mosque mode section header.
  ///
  /// In en, this message translates to:
  /// **'Mosque mode'**
  String get psetMosqueSection;

  /// Calculation method section header.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get psetMethodSection;

  /// Seasonal offsets section header.
  ///
  /// In en, this message translates to:
  /// **'Seasonal offsets'**
  String get psetOffsetsSection;

  /// Health check section header.
  ///
  /// In en, this message translates to:
  /// **'System check'**
  String get psetHealthSection;

  /// Calculation method explainer.
  ///
  /// In en, this message translates to:
  /// **'The method used for all prayer times'**
  String get psetMethodHint;

  /// Adhan enabled subtitle.
  ///
  /// In en, this message translates to:
  /// **'Adhan on'**
  String get psetAdhanOn;

  /// Adhan disabled subtitle.
  ///
  /// In en, this message translates to:
  /// **'Adhan off'**
  String get psetAdhanOff;

  /// Mosque mode toggle title.
  ///
  /// In en, this message translates to:
  /// **'Mosque mode'**
  String get psetMosque;

  /// Mosque mode enabled subtitle.
  ///
  /// In en, this message translates to:
  /// **'Phone silenced automatically at prayer time'**
  String get psetMosqueOn;

  /// Mosque mode disabled subtitle.
  ///
  /// In en, this message translates to:
  /// **'Off — manual only'**
  String get psetMosqueOff;

  /// Mosque mode duration row label.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get psetDuration;

  /// Mosque mode duration value.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String psetDurationMinutes(int minutes);

  /// Quick mosque-mode label.
  ///
  /// In en, this message translates to:
  /// **'Quick enable'**
  String get psetQuick;

  /// 10-minute mosque-mode snackbar.
  ///
  /// In en, this message translates to:
  /// **'Mosque mode — 10 minutes'**
  String get psetQuick10;

  /// 20-minute mosque-mode snackbar.
  ///
  /// In en, this message translates to:
  /// **'Mosque mode — 20 minutes'**
  String get psetQuick20;

  /// 30-minute mosque-mode snackbar.
  ///
  /// In en, this message translates to:
  /// **'Mosque mode — 30 minutes'**
  String get psetQuick30;

  /// Reset seasonal offsets button.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get psetReset;

  /// Run health check button.
  ///
  /// In en, this message translates to:
  /// **'Run system check'**
  String get psetHealthRun;

  /// Health check running label.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get psetHealthRunning;

  /// Healthy report message.
  ///
  /// In en, this message translates to:
  /// **'Everything works perfectly!'**
  String get psetAllGood;

  /// Auto-fix issue button.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get psetFix;

  /// Healthy status badge.
  ///
  /// In en, this message translates to:
  /// **'System healthy'**
  String get psetBadgeHealthy;

  /// Warning status badge.
  ///
  /// In en, this message translates to:
  /// **'There are warnings'**
  String get psetBadgeWarning;

  /// Critical status badge.
  ///
  /// In en, this message translates to:
  /// **'There are critical issues'**
  String get psetBadgeCritical;

  /// Tasbih page app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Electronic tasbih'**
  String get tasbihTitle;

  /// Reset counter tooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get tasbihReset;

  /// 33-count preset chip.
  ///
  /// In en, this message translates to:
  /// **'33'**
  String get tasbihPreset33;

  /// 100-count preset chip.
  ///
  /// In en, this message translates to:
  /// **'100'**
  String get tasbihPreset100;

  /// Open-ended target chip.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get tasbihOpen;

  /// Tasbih hint footer.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere on screen to count'**
  String get tasbihHint;

  /// Tools page header.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// Prayer tool card title.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get toolsPrayer;

  /// Prayer tool card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Times & alerts'**
  String get toolsPrayerSub;

  /// Qibla tool card title.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get toolsQibla;

  /// Qibla tool card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Qibla direction'**
  String get toolsQiblaSub;

  /// Tasbih tool card title.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get toolsTasbih;

  /// Tasbih tool card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Dhikr counter'**
  String get toolsTasbihSub;

  /// Search tool card title.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get toolsSearch;

  /// Search tool card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Search Quran & hadith'**
  String get toolsSearchSub;

  /// Hifz tool card title.
  ///
  /// In en, this message translates to:
  /// **'Memorization & review'**
  String get toolsHifz;

  /// Hifz tool card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Memorize & review verses'**
  String get toolsHifzSub;

  /// Profile tool card title.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get toolsProfile;

  /// Profile tool card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics & progress'**
  String get toolsProfileSub;

  /// Settings tool card subtitle.
  ///
  /// In en, this message translates to:
  /// **'General & appearance settings'**
  String get toolsSettingsSub;

  /// Audio player app-bar title with the surah name.
  ///
  /// In en, this message translates to:
  /// **'Surah {name}'**
  String audioTitle(String name);

  /// Resume dialog title.
  ///
  /// In en, this message translates to:
  /// **'Resume recitation?'**
  String get audioResumeTitle;

  /// Resume dialog body.
  ///
  /// In en, this message translates to:
  /// **'Continue reciting from surah {surah} - verse {ayah}?'**
  String audioResumeBody(String surah, int ayah);

  /// Decline resume button.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get audioNo;

  /// Confirm resume button.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get audioResume;

  /// Current-verse indicator.
  ///
  /// In en, this message translates to:
  /// **'Verse {ayah} of {total}'**
  String audioAyahOf(int ayah, int total);

  /// Surah selector sheet title.
  ///
  /// In en, this message translates to:
  /// **'Pick a surah'**
  String get audioPickSurah;

  /// Reciter selector sheet title.
  ///
  /// In en, this message translates to:
  /// **'Pick a reciter'**
  String get audioPickReciter;

  /// Surah-load error snackbar with the error text.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the surah: {error}'**
  String audioLoadError(String error);

  /// Now-playing badge on the reciter bar.
  ///
  /// In en, this message translates to:
  /// **'Now reciting'**
  String get audioNowPlaying;

  /// Empty mushaf page placeholder.
  ///
  /// In en, this message translates to:
  /// **'Empty page'**
  String get mushafEmpty;

  /// Mushaf page load error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String mushafError(String error);

  /// Page header juz label.
  ///
  /// In en, this message translates to:
  /// **'Juz {juz}'**
  String mushafJuz(int juz);

  /// Reading-appearance button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get mushafAppearanceTooltip;

  /// Mushaf page indicator.
  ///
  /// In en, this message translates to:
  /// **'Page {page} / 604'**
  String mushafPageIndicator(int page);

  /// Copy-verse action.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get mushafCopy;

  /// Bookmark-verse action.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mushafSave;

  /// Bookmark-saved snackbar.
  ///
  /// In en, this message translates to:
  /// **'Bookmark saved'**
  String get mushafSaved;

  /// Share-copy snackbar.
  ///
  /// In en, this message translates to:
  /// **'Copied for sharing'**
  String get mushafShareCopied;

  /// Tafsir preview header.
  ///
  /// In en, this message translates to:
  /// **'Al-Muyassar tafsir'**
  String get mushafTafsirTitle;

  /// Missing-tafsir placeholder.
  ///
  /// In en, this message translates to:
  /// **'Tafsir currently unavailable'**
  String get mushafTafsirMissing;

  /// Expand-tafsir link.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get mushafReadMore;

  /// Open full tafsir button.
  ///
  /// In en, this message translates to:
  /// **'Open full tafsir'**
  String get mushafOpenFull;

  /// Ayah sheet label with surah name and verse number.
  ///
  /// In en, this message translates to:
  /// **'{name} ({ayah})'**
  String mushafAyahLabel(String name, int ayah);

  /// Verse share text.
  ///
  /// In en, this message translates to:
  /// **'{verse} — Holy Quran (surah {surah}, verse {ayah})'**
  String mushafShareTemplate(String verse, String surah, int ayah);

  /// Surah page error state.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the surah'**
  String get surahLoadError;

  /// Surah title fallback when metadata is missing.
  ///
  /// In en, this message translates to:
  /// **'Surah {number}'**
  String surahFallback(int number);

  /// Khushu mode button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Khushu mode'**
  String get surahKhushuTooltip;

  /// Audio button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get surahListenTooltip;

  /// Reading-appearance sheet title.
  ///
  /// In en, this message translates to:
  /// **'Reading appearance'**
  String get surahAppearance;

  /// Translation toggle.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get surahShowTranslation;

  /// Translation language label.
  ///
  /// In en, this message translates to:
  /// **'Translation language:'**
  String get surahTrLang;

  /// Verse options: open tafsir.
  ///
  /// In en, this message translates to:
  /// **'Verse tafsir'**
  String get verseTafsir;

  /// Verse options: add to hifz.
  ///
  /// In en, this message translates to:
  /// **'Add to memorization'**
  String get verseAddHifz;

  /// Added-to-hifz snackbar.
  ///
  /// In en, this message translates to:
  /// **'Verse added to memorization cards'**
  String get verseHifzAdded;

  /// Verse options: bookmark.
  ///
  /// In en, this message translates to:
  /// **'Add bookmark'**
  String get verseAddBookmark;

  /// Bookmark-saved snackbar.
  ///
  /// In en, this message translates to:
  /// **'Bookmark saved'**
  String get verseBookmarkSaved;

  /// Verse options: share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get verseShare;

  /// Share-copy snackbar.
  ///
  /// In en, this message translates to:
  /// **'Verse copied for sharing'**
  String get verseShareCopied;

  /// Verse options: play audio.
  ///
  /// In en, this message translates to:
  /// **'Play audio'**
  String get versePlayAudio;

  /// Verse options: copy.
  ///
  /// In en, this message translates to:
  /// **'Copy verse'**
  String get verseCopy;

  /// Copied snackbar.
  ///
  /// In en, this message translates to:
  /// **'Verse copied'**
  String get verseCopied;

  /// Verse share text.
  ///
  /// In en, this message translates to:
  /// **'{verse} — Holy Quran (surah {surah}, verse {ayah})'**
  String verseShareTemplate(String verse, int surah, int ayah);

  /// Quran library header.
  ///
  /// In en, this message translates to:
  /// **'Holy Quran'**
  String get quranTitle;

  /// Surah count badge.
  ///
  /// In en, this message translates to:
  /// **'{count} surahs'**
  String quranSurahCount(int count);

  /// Continue-reading card title.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get quranContinue;

  /// Continue-reading surah line.
  ///
  /// In en, this message translates to:
  /// **'Surah no. {number}'**
  String quranSurahNumber(String number);

  /// Empty search state.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get quranNoResults;

  /// Mushaf shortcut button.
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get quranMushaf;

  /// Khatmah shortcut button.
  ///
  /// In en, this message translates to:
  /// **'Khatmah plan'**
  String get quranKhatmahPlan;

  /// Tafsir shortcut button.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get quranTafsir;

  /// Show-all filter chip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get quranFilterAll;

  /// Makki filter chip and badge.
  ///
  /// In en, this message translates to:
  /// **'Makki'**
  String get quranMeccan;

  /// Madani filter chip and badge.
  ///
  /// In en, this message translates to:
  /// **'Madani'**
  String get quranMedinan;

  /// Surah search hint.
  ///
  /// In en, this message translates to:
  /// **'Search for a surah...'**
  String get quranSearchHint;

  /// Verse count per surah tile.
  ///
  /// In en, this message translates to:
  /// **'{count} verses'**
  String quranAyahCount(int count);

  /// Quran list error title.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get quranError;

  /// Khatmah page app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Khatmah plan'**
  String get khatmahTitle;

  /// Empty khatmah state.
  ///
  /// In en, this message translates to:
  /// **'No active khatmah'**
  String get khatmahEmpty;

  /// Start-khatmah button.
  ///
  /// In en, this message translates to:
  /// **'Start a new khatmah'**
  String get khatmahStart;

  /// Schedule section header.
  ///
  /// In en, this message translates to:
  /// **'Reading schedule'**
  String get khatmahSchedule;

  /// History section header.
  ///
  /// In en, this message translates to:
  /// **'Your past khatmahs'**
  String get khatmahHistory;

  /// Empty history state.
  ///
  /// In en, this message translates to:
  /// **'No khatmah completed yet'**
  String get khatmahNoneDone;

  /// Active khatmah badge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get khatmahActive;

  /// Progress page fraction.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String khatmahPageOfTotal(int current, int total);

  /// Last-position label.
  ///
  /// In en, this message translates to:
  /// **'Last position'**
  String get khatmahLastPosition;

  /// Last-position line.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah} - verse {ayah}'**
  String khatmahPositionAt(String surah, int ayah);

  /// Resume-reading button.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get khatmahResume;

  /// Target-date line.
  ///
  /// In en, this message translates to:
  /// **'Goal: {date}'**
  String khatmahGoal(String date);

  /// Daily goal card title.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal'**
  String get khatmahDailyGoal;

  /// Daily pages fraction.
  ///
  /// In en, this message translates to:
  /// **'{read} / {need} pages'**
  String khatmahPagesToday(int read, int need);

  /// Goal-complete celebration.
  ///
  /// In en, this message translates to:
  /// **'Well done! Daily goal complete'**
  String get khatmahGoalDone;

  /// Schedule row pages.
  ///
  /// In en, this message translates to:
  /// **'{pages} pages'**
  String khatmahSchedulePages(String pages);

  /// Past-khatmah duration.
  ///
  /// In en, this message translates to:
  /// **'Completed in {days} days'**
  String khatmahDoneIn(int days);

  /// New-khatmah dialog title.
  ///
  /// In en, this message translates to:
  /// **'New khatmah'**
  String get khatmahNew;

  /// Khatmah name hint.
  ///
  /// In en, this message translates to:
  /// **'Khatmah name (optional)'**
  String get khatmahNameHint;

  /// Duration row label.
  ///
  /// In en, this message translates to:
  /// **'Duration:'**
  String get khatmahDuration;

  /// Duration dropdown option.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String khatmahDaysOption(int days);

  /// Pages-per-day estimate.
  ///
  /// In en, this message translates to:
  /// **'About {pages} pages per day'**
  String khatmahPerDay(int pages);

  /// Confirm-start button.
  ///
  /// In en, this message translates to:
  /// **'Start khatmah'**
  String get khatmahStartButton;

  /// Tadabbur page title.
  ///
  /// In en, this message translates to:
  /// **'Tadabbur mihrab'**
  String get tadTitle;

  /// Note-saved snackbar.
  ///
  /// In en, this message translates to:
  /// **'Your note was saved securely'**
  String get tadSaved;

  /// Verse reference line.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah} - verse {ayah}'**
  String tadRef(int surah, int ayah);

  /// Note input hint.
  ///
  /// In en, this message translates to:
  /// **'Write your reflections here...'**
  String get tadHint;

  /// Encryption reassurance line.
  ///
  /// In en, this message translates to:
  /// **'Your notes are encrypted locally'**
  String get tadEncrypted;

  /// Save-note button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get tadSave;

  /// Saved-notes header.
  ///
  /// In en, this message translates to:
  /// **'Your previous notes'**
  String get tadPrevious;

  /// Empty notes state.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get tadEmpty;

  /// Privacy dialog title.
  ///
  /// In en, this message translates to:
  /// **'Your notes\' privacy'**
  String get tadPrivacyTitle;

  /// Privacy row 1.
  ///
  /// In en, this message translates to:
  /// **'Your notes are encrypted locally on your device'**
  String get tadPrivacy1;

  /// Privacy row 2.
  ///
  /// In en, this message translates to:
  /// **'Never uploaded to any cloud'**
  String get tadPrivacy2;

  /// Privacy row 3.
  ///
  /// In en, this message translates to:
  /// **'Nobody can read them but you'**
  String get tadPrivacy3;

  /// Privacy AES note.
  ///
  /// In en, this message translates to:
  /// **'Uses AES-256 encryption to protect your thoughts.'**
  String get tadPrivacyAes;

  /// Privacy dialog dismiss button.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get tadGotIt;

  /// Topic tree app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Topic taxonomy'**
  String get topicTitle;

  /// Empty topic index state.
  ///
  /// In en, this message translates to:
  /// **'No topics yet'**
  String get topicEmpty;

  /// Empty topic index hint.
  ///
  /// In en, this message translates to:
  /// **'The index builds on the first hadith load'**
  String get topicEmptyHint;

  /// Hadith count per topic.
  ///
  /// In en, this message translates to:
  /// **'{count} hadith'**
  String topicHadithCount(int count);

  /// Memorization page title.
  ///
  /// In en, this message translates to:
  /// **'Hadith memorization'**
  String get memTitle;

  /// Due-cards stat label.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get memDueToday;

  /// Reviewed-today stat label.
  ///
  /// In en, this message translates to:
  /// **'Reviewed today'**
  String get memReviewedToday;

  /// Total-memorized stat label.
  ///
  /// In en, this message translates to:
  /// **'Total memorized'**
  String get memTotal;

  /// Card-front hint when no card is loaded.
  ///
  /// In en, this message translates to:
  /// **'The Prophet said: ...'**
  String get memHintFallback;

  /// Card-front prompt.
  ///
  /// In en, this message translates to:
  /// **'Recall the hadith...'**
  String get memRemember;

  /// Reveal-answer hint.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal the answer'**
  String get memShowAnswer;

  /// Fallback review-interval label.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get memDayFallback;

  /// Completion empty state title.
  ///
  /// In en, this message translates to:
  /// **'Well done! Today\'s review is complete'**
  String get memDone;

  /// Completion empty state subtitle.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow to keep memorizing'**
  String get memComeBack;

  /// Leave-completed-deck button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get memBack;

  /// Learning statistics title.
  ///
  /// In en, this message translates to:
  /// **'My statistics'**
  String get lstatsTitle;

  /// Bookmarks stat.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get lstatsBookmarks;

  /// Bookmarks unit.
  ///
  /// In en, this message translates to:
  /// **'hadith'**
  String get lstatsHadithUnit;

  /// Notes stat.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get lstatsNotes;

  /// Notes unit.
  ///
  /// In en, this message translates to:
  /// **'notes'**
  String get lstatsNoteUnit;

  /// Quizzes stat.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get lstatsQuizzes;

  /// Quiz average subtitle.
  ///
  /// In en, this message translates to:
  /// **'{score}% average'**
  String lstatsQuizAvg(int score);

  /// Memorized stat.
  ///
  /// In en, this message translates to:
  /// **'Memorized'**
  String get lstatsMemorize;

  /// Memorized unit.
  ///
  /// In en, this message translates to:
  /// **'cards'**
  String get lstatsCardUnit;

  /// Weekly chart header.
  ///
  /// In en, this message translates to:
  /// **'Week activity'**
  String get lstatsWeekActivity;

  /// Per-book section header.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks by book'**
  String get lstatsByBooks;

  /// Streak card title.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get lstatsStreak;

  /// Longest-streak line.
  ///
  /// In en, this message translates to:
  /// **'Longest streak: {days} days'**
  String lstatsLongest(int days);

  /// Per-book saved count.
  ///
  /// In en, this message translates to:
  /// **'{read} saved'**
  String lstatsBookSaved(int read);

  /// Streak banner with emoji.
  ///
  /// In en, this message translates to:
  /// **'{emoji} Practice streak'**
  String hifzStreakLine(String emoji);

  /// Streak day count.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String hifzDays(int count);

  /// New-cards chip.
  ///
  /// In en, this message translates to:
  /// **'To memorize'**
  String get hifzToMemorize;

  /// Due-cards chip.
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get hifzToReview;

  /// Start-review button.
  ///
  /// In en, this message translates to:
  /// **'Start review ({count})'**
  String hifzStartReview(int count);

  /// Start-new button.
  ///
  /// In en, this message translates to:
  /// **'Start memorizing {count} new verses'**
  String hifzStartNew(int count);

  /// Empty hifz state.
  ///
  /// In en, this message translates to:
  /// **'Add verses from a surah page to start memorizing'**
  String get hifzEmpty;

  /// Cards section header.
  ///
  /// In en, this message translates to:
  /// **'My cards ({count})'**
  String hifzMyCards(int count);

  /// Card reference line.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah} : verse {ayah}'**
  String hifzCardRef(int surah, int ayah);

  /// New-card badge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get hifzNew;

  /// Due-card badge.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get hifzDueToday;

  /// Future-review badge.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String hifzAfterDays(int days);

  /// Repeat-count label.
  ///
  /// In en, this message translates to:
  /// **'Repeats: '**
  String get hifzRepeat;

  /// Unified search hint.
  ///
  /// In en, this message translates to:
  /// **'Search Quran & hadith...'**
  String get searchHintUnified;

  /// Search idle prompt.
  ///
  /// In en, this message translates to:
  /// **'Search for a verse or hadith'**
  String get searchPrompt;

  /// Hadith result badge.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get searchBadgeHadith;

  /// Adhkar result badge.
  ///
  /// In en, this message translates to:
  /// **'Adhkar'**
  String get searchBadgeAdhkar;

  /// Quran result reference.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah} : verse {verse}'**
  String searchQuranRef(String surah, String verse);

  /// Copy-result snackbar.
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get searchCopied;

  /// Hadith search title.
  ///
  /// In en, this message translates to:
  /// **'Advanced search'**
  String get hsearchTitle;

  /// All-books dropdown option.
  ///
  /// In en, this message translates to:
  /// **'All books'**
  String get hsearchAllBooks;

  /// Search submit button.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get hsearchButton;

  /// Idle search state.
  ///
  /// In en, this message translates to:
  /// **'Search the nine books'**
  String get hsearchEmpty;

  /// Idle search subtitle.
  ///
  /// In en, this message translates to:
  /// **'Search covers Arabic and English text'**
  String get hsearchEmptySub;

  /// No-results state.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get hsearchNoResults;

  /// Result count badge.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String hsearchCount(int count);

  /// Text-search mode.
  ///
  /// In en, this message translates to:
  /// **'Text search'**
  String get hsearchByText;

  /// Narrator-search mode.
  ///
  /// In en, this message translates to:
  /// **'Narrator search'**
  String get hsearchByNarrator;

  /// Text-search hint.
  ///
  /// In en, this message translates to:
  /// **'Search by word or phrase...'**
  String get hsearchTextHint;

  /// Narrator-search hint.
  ///
  /// In en, this message translates to:
  /// **'Narrator name in English...'**
  String get hsearchNarratorHint;

  /// Result card hadith number.
  ///
  /// In en, this message translates to:
  /// **'Hadith no. {id}'**
  String hsearchHadithNumber(int id);

  /// Session-complete dialog title.
  ///
  /// In en, this message translates to:
  /// **'Masha Allah!'**
  String get hsessionDoneTitle;

  /// Session-complete dialog body.
  ///
  /// In en, this message translates to:
  /// **'Session complete. Keep practicing daily to retain memorization.'**
  String get hsessionDoneBody;

  /// Leave-session button.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get hsessionFinish;

  /// Session progress counter.
  ///
  /// In en, this message translates to:
  /// **'Memorization session ({index}/{total})'**
  String hsessionCounter(int index, int total);

  /// Session card reference.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah} — verse {ayah}'**
  String hsessionCardRef(int surah, int ayah);

  /// Repeat counter label.
  ///
  /// In en, this message translates to:
  /// **'Repeats x{count}'**
  String hsessionRepeatCount(int count);

  /// Self-rating prompt.
  ///
  /// In en, this message translates to:
  /// **'How was your recall?'**
  String get hsessionRatePrompt;

  /// Review-interval label.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String hsessionIntervalDays(int days);

  /// Hadith library header title.
  ///
  /// In en, this message translates to:
  /// **'Jawami al-Kalim'**
  String get hpageTitle;

  /// Hadith library header subtitle.
  ///
  /// In en, this message translates to:
  /// **'Library of the noble Prophetic Sunnah'**
  String get hpageSubtitle;

  /// Bookmarks button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get hpageBookmarksTooltip;

  /// Quiz button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Hadith quiz'**
  String get hpageQuizTooltip;

  /// Books section header.
  ///
  /// In en, this message translates to:
  /// **'Books & collections'**
  String get hpageBooks;

  /// Books section subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a book to browse hadith'**
  String get hpageBooksHint;

  /// Book card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Hadith collection'**
  String get hpageBookCollection;

  /// Books-load error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String hpageError(String error);

  /// Study tools header.
  ///
  /// In en, this message translates to:
  /// **'Study tools'**
  String get hpageStudyTools;

  /// Memorization tool tile.
  ///
  /// In en, this message translates to:
  /// **'Spaced memorization'**
  String get hpageToolMemorize;

  /// Statistics tool tile.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get hpageToolStats;

  /// Tags tool tile.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get hpageToolTags;

  /// Topics tool tile.
  ///
  /// In en, this message translates to:
  /// **'Topic tree'**
  String get hpageToolTopics;

  /// Advanced browser tool tile.
  ///
  /// In en, this message translates to:
  /// **'Advanced browser'**
  String get hpageToolAdvanced;

  /// Continue-reading card title.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get hpageContinue;

  /// Continue-reading position line.
  ///
  /// In en, this message translates to:
  /// **'{title} - hadith {index} / {total}'**
  String hpageContinueAt(String title, int index, int total);

  /// Hadith-of-the-day badge.
  ///
  /// In en, this message translates to:
  /// **'Hadith of the day'**
  String get hpageToday;

  /// Read-more link.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get hpageReadMore;

  /// Unbookmark snackbar.
  ///
  /// In en, this message translates to:
  /// **'Hadith removed from bookmarks'**
  String get hbmRemoved;

  /// Empty bookmarks state.
  ///
  /// In en, this message translates to:
  /// **'No bookmarked hadith'**
  String get hbmEmpty;

  /// Empty bookmarks hint.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon while reading a hadith'**
  String get hbmEmptyHint;

  /// Create-tag sheet title.
  ///
  /// In en, this message translates to:
  /// **'Create new tag'**
  String get tagsNew;

  /// Tag name hint.
  ///
  /// In en, this message translates to:
  /// **'Tag name (e.g. for review)'**
  String get tagsNameHint;

  /// Icon picker label.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get tagsIcon;

  /// Color picker label.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get tagsColor;

  /// Create-tag button.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get tagsCreate;

  /// Tags page title.
  ///
  /// In en, this message translates to:
  /// **'My tags'**
  String get tagsTitle;

  /// Empty tags state.
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get tagsEmpty;

  /// Empty tags hint.
  ///
  /// In en, this message translates to:
  /// **'Create tags to organize your favorite hadith'**
  String get tagsEmptyHint;

  /// New-tag FAB.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get tagsNewFab;

  /// Untag snackbar.
  ///
  /// In en, this message translates to:
  /// **'Hadith removed from tag'**
  String get tagsRemoved;

  /// Tag snackbar.
  ///
  /// In en, this message translates to:
  /// **'Hadith added to tag'**
  String get tagsAdded;

  /// Comparison page title.
  ///
  /// In en, this message translates to:
  /// **'Narration comparison'**
  String get cmpTitle;

  /// Diff toggle tooltip.
  ///
  /// In en, this message translates to:
  /// **'Show differences'**
  String get cmpDiffTooltip;

  /// Side-by-side button.
  ///
  /// In en, this message translates to:
  /// **'Side-by-side view'**
  String get cmpSideBySide;

  /// Empty comparison state.
  ///
  /// In en, this message translates to:
  /// **'No matching narrations found'**
  String get cmpEmpty;

  /// Empty comparison hint.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword'**
  String get cmpEmptyHint;

  /// Missing-grade fallback.
  ///
  /// In en, this message translates to:
  /// **'Ungraded'**
  String get cmpUngraded;

  /// Difference count badge.
  ///
  /// In en, this message translates to:
  /// **'{count} differences'**
  String cmpDiffCount(int count);

  /// Side-by-side sheet title.
  ///
  /// In en, this message translates to:
  /// **'Side-by-side comparison'**
  String get cmpSideTitle;

  /// Complete-the-hadith quiz title.
  ///
  /// In en, this message translates to:
  /// **'Complete the hadith'**
  String get quizComplete;

  /// Choose-correct quiz title.
  ///
  /// In en, this message translates to:
  /// **'Choose correctly'**
  String get quizChoose;

  /// Narrator quiz title.
  ///
  /// In en, this message translates to:
  /// **'Identify the narrator'**
  String get quizNarrator;

  /// Grade quiz title.
  ///
  /// In en, this message translates to:
  /// **'Hadith grade'**
  String get quizGrade;

  /// Quiz progress header.
  ///
  /// In en, this message translates to:
  /// **'Question {index} of {total}'**
  String quizQuestion(int index, int total);

  /// Quiz passed title.
  ///
  /// In en, this message translates to:
  /// **'Well done!'**
  String get quizPassed;

  /// Quiz failed title.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get quizFailed;

  /// Quiz score line.
  ///
  /// In en, this message translates to:
  /// **'{score} of {total} correct answers'**
  String quizScore(int score, int total);

  /// Retake button.
  ///
  /// In en, this message translates to:
  /// **'Retake quiz'**
  String get quizRetry;

  /// Chapters loading state.
  ///
  /// In en, this message translates to:
  /// **'Loading chapters...'**
  String get hchLoading;

  /// Chapters error state.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the book'**
  String get hchError;

  /// Chapter count chip.
  ///
  /// In en, this message translates to:
  /// **'{count} chapters'**
  String hchChapters(int count);

  /// All-hadith list title.
  ///
  /// In en, this message translates to:
  /// **'All hadith'**
  String get hchAllTitle;

  /// View-all button.
  ///
  /// In en, this message translates to:
  /// **'View all hadith'**
  String get hchViewAll;

  /// Chapters section header.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get hchSection;

  /// Per-chapter unit label.
  ///
  /// In en, this message translates to:
  /// **'hadith'**
  String get hchHadithUnit;

  /// Empty chapter state.
  ///
  /// In en, this message translates to:
  /// **'No hadith in this chapter'**
  String get hchEmpty;

  /// Isnad graph title.
  ///
  /// In en, this message translates to:
  /// **'Isnad graph'**
  String get igTitle;

  /// Chain size chip.
  ///
  /// In en, this message translates to:
  /// **'{count} narrators'**
  String igCount(int count);

  /// Graph loading state.
  ///
  /// In en, this message translates to:
  /// **'Analyzing the isnad...'**
  String get igLoading;

  /// Empty graph state.
  ///
  /// In en, this message translates to:
  /// **'No isnad found'**
  String get igEmpty;

  /// Chain page title.
  ///
  /// In en, this message translates to:
  /// **'Isnad chain'**
  String get ichainTitle;

  /// Graph toggle tooltip.
  ///
  /// In en, this message translates to:
  /// **'Graph view'**
  String get ichainGraphTooltip;

  /// Chain loading state.
  ///
  /// In en, this message translates to:
  /// **'Analyzing the isnad chain...'**
  String get ichainLoading;

  /// Empty chain hint.
  ///
  /// In en, this message translates to:
  /// **'This hadith text has no analyzable isnad chain'**
  String get ichainEmptyHint;

  /// Chain size badge.
  ///
  /// In en, this message translates to:
  /// **'{count} narrators in the chain'**
  String ichainCount(int count);

  /// Narrator detail sheet title.
  ///
  /// In en, this message translates to:
  /// **'Narrator card'**
  String get ichainCardTitle;

  /// Bookmark snackbar.
  ///
  /// In en, this message translates to:
  /// **'Hadith added to bookmarks'**
  String get hreaderBookmarked;

  /// Copy snackbar.
  ///
  /// In en, this message translates to:
  /// **'Hadith copied'**
  String get hreaderCopied;

  /// Hadith copy text.
  ///
  /// In en, this message translates to:
  /// **'{text}\n\n{narrator}\n\n— {title} #{id}'**
  String hreaderCopyTemplate(
      String text, String title, int id, String narrator);

  /// Reader app-bar title.
  ///
  /// In en, this message translates to:
  /// **'{title} — #{id}'**
  String hreaderTitle(String title, int id);

  /// Sharh button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Commentary'**
  String get hreaderSharahTooltip;

  /// Hadith number badge.
  ///
  /// In en, this message translates to:
  /// **'Hadith #{id}'**
  String hreaderNumberBadge(int id);

  /// Previous button.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get hreaderPrev;

  /// Next button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get hreaderNext;

  /// Share sheet title.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get hshareTitle;

  /// Share button.
  ///
  /// In en, this message translates to:
  /// **'Share now'**
  String get hshareNow;

  /// Share processing label.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get hshareProcessing;

  /// Shared image caption.
  ///
  /// In en, this message translates to:
  /// **'{title} - hadith no. {id}\n\nNoor Islamic app'**
  String hshareText(String title, int id);

  /// Share error snackbar.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the image: {error}'**
  String hshareError(String error);

  /// Scholar mode title.
  ///
  /// In en, this message translates to:
  /// **'Student-of-knowledge mode'**
  String get schTitle;

  /// Highlight toggle tooltip.
  ///
  /// In en, this message translates to:
  /// **'Highlight key words'**
  String get schHighlightTooltip;

  /// Takhrij share tooltip.
  ///
  /// In en, this message translates to:
  /// **'Share with documentation'**
  String get schShareTooltip;

  /// Missing-grade fallback.
  ///
  /// In en, this message translates to:
  /// **'Ungraded'**
  String get schUngraded;

  /// Hadith number line.
  ///
  /// In en, this message translates to:
  /// **'Hadith no. {number}'**
  String schHadithNumber(int number);

  /// Takhrij section title.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get schTakhrij;

  /// Takhrij book row.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get schBook;

  /// Takhrij chapter row.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get schChapter;

  /// Takhrij chapter value.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapter}'**
  String schChapterValue(int chapter);

  /// Takhrij number row.
  ///
  /// In en, this message translates to:
  /// **'Hadith number'**
  String get schNumber;

  /// Takhrij companion row.
  ///
  /// In en, this message translates to:
  /// **'Companion'**
  String get schCompanion;

  /// Takhrij topics row.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get schTopics;

  /// Notes section title.
  ///
  /// In en, this message translates to:
  /// **'My notes'**
  String get schNotes;

  /// Notes hint.
  ///
  /// In en, this message translates to:
  /// **'Add your notes on this hadith...'**
  String get schNotesHint;

  /// Notes autosave note.
  ///
  /// In en, this message translates to:
  /// **'Notes save automatically'**
  String get schNotesSaved;

  /// Similar section title.
  ///
  /// In en, this message translates to:
  /// **'Similar hadith'**
  String get schSimilar;

  /// Empty similar state.
  ///
  /// In en, this message translates to:
  /// **'No similar hadith'**
  String get schNoSimilar;

  /// Empty isnad state.
  ///
  /// In en, this message translates to:
  /// **'No isnad found in this hadith'**
  String get schNoIsnad;

  /// Isnad section title.
  ///
  /// In en, this message translates to:
  /// **'Isnad analysis'**
  String get schIsnadAnalysis;

  /// Chain size subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} narrators in the chain'**
  String schChainCount(int count);

  /// Narrator stat.
  ///
  /// In en, this message translates to:
  /// **'Narrators'**
  String get schStatNarrators;

  /// Companion stat.
  ///
  /// In en, this message translates to:
  /// **'Companions'**
  String get schStatCompanions;

  /// Prophet stat.
  ///
  /// In en, this message translates to:
  /// **'The Prophet'**
  String get schStatProphet;

  /// Connected-chain banner.
  ///
  /// In en, this message translates to:
  /// **'Connected chain ({count} links)'**
  String schChainConnected(int count);

  /// Short-chain banner.
  ///
  /// In en, this message translates to:
  /// **'Short chain ({count} links)'**
  String schChainShort(int count);

  /// Copy-takhrij chip.
  ///
  /// In en, this message translates to:
  /// **'Copy with documentation'**
  String get schCopyTakhrij;

  /// Review chip.
  ///
  /// In en, this message translates to:
  /// **'Save for review'**
  String get schSaveReview;

  /// Copied snackbar.
  ///
  /// In en, this message translates to:
  /// **'Copied with documentation'**
  String get schCopiedTakhrij;

  /// Saved-for-review snackbar.
  ///
  /// In en, this message translates to:
  /// **'Added to review'**
  String get schAddedReview;

  /// Copied documentation book line.
  ///
  /// In en, this message translates to:
  /// **'Book: {book}'**
  String schTakhrijBook(String book);

  /// Copied documentation chapter line.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapter} - hadith {number}'**
  String schTakhrijChapter(int chapter, int number);

  /// Copied documentation grade line.
  ///
  /// In en, this message translates to:
  /// **'Grade: {grade}'**
  String schTakhrijGrade(String grade);

  /// Copied documentation companion line.
  ///
  /// In en, this message translates to:
  /// **'Companion: {companion}'**
  String schTakhrijCompanion(String companion);

  /// Copied documentation footer.
  ///
  /// In en, this message translates to:
  /// **'— Noor Islamic app'**
  String get schTakhrijApp;

  /// Search tab.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get advTabSearch;

  /// Companions tab.
  ///
  /// In en, this message translates to:
  /// **'Companions'**
  String get advTabCompanions;

  /// Topics tab.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get advTabTopics;

  /// Books tab.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get advTabBooks;

  /// Search input hint.
  ///
  /// In en, this message translates to:
  /// **'Type text to search...'**
  String get advSearchHint;

  /// Scope label.
  ///
  /// In en, this message translates to:
  /// **'Search scope:'**
  String get advScope;

  /// Matn scope chip.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get advFilterMatn;

  /// Sanad scope chip.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get advFilterSanad;

  /// Book filter chip.
  ///
  /// In en, this message translates to:
  /// **'Filter by books'**
  String get advFilterBooks;

  /// Mode label.
  ///
  /// In en, this message translates to:
  /// **'Search mode:'**
  String get advMode;

  /// Smart mode.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get advModeSmart;

  /// Any-word mode.
  ///
  /// In en, this message translates to:
  /// **'Any word'**
  String get advModeAny;

  /// All-words mode.
  ///
  /// In en, this message translates to:
  /// **'All words'**
  String get advModeAll;

  /// Phrase mode.
  ///
  /// In en, this message translates to:
  /// **'Phrase'**
  String get advModePhrase;

  /// Root mode.
  ///
  /// In en, this message translates to:
  /// **'By root'**
  String get advModeRoot;

  /// Narrator filter hint.
  ///
  /// In en, this message translates to:
  /// **'A narrator in the chain...'**
  String get advNarratorHint;

  /// Number-from hint.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get advFromHint;

  /// Number-to hint.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get advToHint;

  /// Grade label.
  ///
  /// In en, this message translates to:
  /// **'Grade:'**
  String get advGrade;

  /// Empty search title.
  ///
  /// In en, this message translates to:
  /// **'Hadith encyclopedia'**
  String get advEmptyTitle;

  /// Empty search body.
  ///
  /// In en, this message translates to:
  /// **'Search thousands of Prophetic hadith from the nine canonical books'**
  String get advEmptyBody;

  /// All-books filter option.
  ///
  /// In en, this message translates to:
  /// **'All books'**
  String get advAllBooksOption;

  /// Number-range chip.
  ///
  /// In en, this message translates to:
  /// **'No. {from} - {to}'**
  String advRangeBoth(int from, int to);

  /// Number-from chip.
  ///
  /// In en, this message translates to:
  /// **'No. from {from}'**
  String advRangeFrom(int from);

  /// Number-to chip.
  ///
  /// In en, this message translates to:
  /// **'No. to {to}'**
  String advRangeTo(int to);

  /// Result score badge.
  ///
  /// In en, this message translates to:
  /// **'{score}% match'**
  String advMatchScore(String score);

  /// Result book/number line.
  ///
  /// In en, this message translates to:
  /// **'{book} - {number}'**
  String advBookNumber(String book, int number);

  /// Scholar-mode button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Scholar mode'**
  String get layScholarTooltip;

  /// Matn tab.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get layTabMatn;

  /// Sanad tab.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get layTabSanad;

  /// Ruling tab.
  ///
  /// In en, this message translates to:
  /// **'Ruling'**
  String get layTabHukm;

  /// Copy-matn tooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get layCopyMatn;

  /// Chain section title.
  ///
  /// In en, this message translates to:
  /// **'Narrator chain'**
  String get layChainTitle;

  /// Full-sanad header.
  ///
  /// In en, this message translates to:
  /// **'Full chain'**
  String get layFullSanad;

  /// Companion subtitle.
  ///
  /// In en, this message translates to:
  /// **'A noble Companion'**
  String get layCompanionRaa;

  /// Grade legend header.
  ///
  /// In en, this message translates to:
  /// **'Rulings guide'**
  String get layGradeGuide;

  /// Takhrij chapter line.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapter}'**
  String layChapterOf(int chapter);

  /// Takhrij number line.
  ///
  /// In en, this message translates to:
  /// **'Hadith no. {number}'**
  String layHadithOf(int number);

  /// Cross-reference header.
  ///
  /// In en, this message translates to:
  /// **'This hadith in other books'**
  String get layOtherBooks;

  /// Empty cross-reference state.
  ///
  /// In en, this message translates to:
  /// **'Not found in other books'**
  String get layNotInOthers;

  /// Similar-hadith subtitle.
  ///
  /// In en, this message translates to:
  /// **'Hadith {number}'**
  String laySimilarNumber(int number);

  /// Copy-takhrij button.
  ///
  /// In en, this message translates to:
  /// **'Copy full documentation'**
  String get layCopyTakhrij;

  /// Copied snackbar.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get layCopied;

  /// Copied documentation number line.
  ///
  /// In en, this message translates to:
  /// **'Hadith no. {number}'**
  String layTakhrijNumber(int number);

  /// Copied documentation chapter line.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapter}'**
  String layTakhrijChapter(int chapter);

  /// Layered copied grade line.
  ///
  /// In en, this message translates to:
  /// **'Grade: {grade}'**
  String layTakhrijGrade(String grade);

  /// Layered copied companion line.
  ///
  /// In en, this message translates to:
  /// **'Companion: {companion}'**
  String layTakhrijCompanion(String companion);

  /// Sharh sheet title.
  ///
  /// In en, this message translates to:
  /// **'Hadith commentary #{id}'**
  String sharhTitle(int id);

  /// Matn section title.
  ///
  /// In en, this message translates to:
  /// **'Hadith text'**
  String get sharhMatn;

  /// Takhrij section title.
  ///
  /// In en, this message translates to:
  /// **'Documentation & grade'**
  String get sharhTakhrij;

  /// Book info row.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get sharhBook;

  /// Number info row.
  ///
  /// In en, this message translates to:
  /// **'Hadith number'**
  String get sharhNumber;

  /// Narrator info row.
  ///
  /// In en, this message translates to:
  /// **'Narrator'**
  String get sharhNarrator;

  /// Source info row.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sharhSource;

  /// Benefits section title.
  ///
  /// In en, this message translates to:
  /// **'Hadith benefits'**
  String get sharhBenefits;

  /// Notes section title.
  ///
  /// In en, this message translates to:
  /// **'My notes'**
  String get sharhNotes;

  /// Notes hint.
  ///
  /// In en, this message translates to:
  /// **'Write your notes and reflections here...'**
  String get sharhNotesHint;

  /// Note-saved snackbar.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get sharhNoteSaved;

  /// Similar section title.
  ///
  /// In en, this message translates to:
  /// **'Similar hadith'**
  String get sharhSimilar;

  /// Study tools title.
  ///
  /// In en, this message translates to:
  /// **'Study tools'**
  String get sharhTools;

  /// Isnad map button.
  ///
  /// In en, this message translates to:
  /// **'Isnad map'**
  String get sharhIsnadMap;

  /// Isnad map subtitle.
  ///
  /// In en, this message translates to:
  /// **'Hadith narrator chain'**
  String get sharhIsnadMapSub;

  /// Isnad graph subtitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive narrator-chain view'**
  String get sharhIsnadGraphSub;

  /// Compare button.
  ///
  /// In en, this message translates to:
  /// **'Compare narrations'**
  String get sharhCompare;

  /// Compare subtitle.
  ///
  /// In en, this message translates to:
  /// **'Different wordings across books'**
  String get sharhCompareSub;

  /// Tag button.
  ///
  /// In en, this message translates to:
  /// **'Add to a tag'**
  String get sharhAddTag;

  /// Tag subtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize hadith in your lists'**
  String get sharhAddTagSub;

  /// Adhkar page title.
  ///
  /// In en, this message translates to:
  /// **'Daily adhkar'**
  String get adhkarTitle;

  /// Adhkar streak badge.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String adhkarStreakDays(int count);

  /// Morning category title.
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar'**
  String get adhkarMorning;

  /// Evening category title.
  ///
  /// In en, this message translates to:
  /// **'Evening adhkar'**
  String get adhkarEvening;

  /// After-prayer category title.
  ///
  /// In en, this message translates to:
  /// **'After prayer'**
  String get adhkarAfterPrayer;

  /// Sleep category title.
  ///
  /// In en, this message translates to:
  /// **'Sleep adhkar'**
  String get adhkarSleep;

  /// Wake-up category title.
  ///
  /// In en, this message translates to:
  /// **'Waking up'**
  String get adhkarWakeup;

  /// Quranic duas category title.
  ///
  /// In en, this message translates to:
  /// **'Quranic duas'**
  String get adhkarQuranic;

  /// Library category title.
  ///
  /// In en, this message translates to:
  /// **'Adhkar library'**
  String get adhkarLibrary;

  /// Library category subtitle.
  ///
  /// In en, this message translates to:
  /// **'100+ sourced adhkar'**
  String get adhkarLibrarySub;

  /// Count unit for dhikr.
  ///
  /// In en, this message translates to:
  /// **'adhkar'**
  String get adhkarUnitZekr;

  /// Count unit for dua.
  ///
  /// In en, this message translates to:
  /// **'duas'**
  String get adhkarUnitDua;

  /// Completed progress title.
  ///
  /// In en, this message translates to:
  /// **'Well done! Today\'s portion complete'**
  String get adhkarTodayDone;

  /// Progress title.
  ///
  /// In en, this message translates to:
  /// **'Today\'s portion'**
  String get adhkarToday;

  /// Morning status chip.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get adhkarChipMorning;

  /// Evening status chip.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get adhkarChipEvening;

  /// Completed progress subtitle.
  ///
  /// In en, this message translates to:
  /// **'May God bless you'**
  String get adhkarBlessed;

  /// Remaining portions line.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {list}'**
  String adhkarRemainingJoined(String list);

  /// All-done fallback.
  ///
  /// In en, this message translates to:
  /// **'Today\'s adhkar complete!'**
  String get adhkarAllDone;

  /// Completion dialog body with the collection name.
  ///
  /// In en, this message translates to:
  /// **'You completed {name}'**
  String adhkarCongratsBody(String name);

  /// Completion dialog button.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adhkarDone;

  /// Empty collection state.
  ///
  /// In en, this message translates to:
  /// **'No adhkar'**
  String get adhkarNoAdhkar;

  /// Completed-view subtitle.
  ///
  /// In en, this message translates to:
  /// **'May God bless and accept from you'**
  String get adhkarBlessAccept;

  /// Back-to-list button.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get adhkarBackToList;

  /// Counter total line.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String adhkarOfTotal(int total);

  /// Source selector tooltip.
  ///
  /// In en, this message translates to:
  /// **'Pick a tafsir'**
  String get tafsirPickTooltip;

  /// Bookmarks tab.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get tafsirTabBookmarks;

  /// History tab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tafsirTabHistory;

  /// Surah dropdown label.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get tafsirSurahLabel;

  /// Missing-surah-tafsir state.
  ///
  /// In en, this message translates to:
  /// **'No tafsir for this surah'**
  String get tafsirNoTafsir;

  /// Empty bookmarks state.
  ///
  /// In en, this message translates to:
  /// **'No saved bookmarks'**
  String get tafsirNoBookmarks;

  /// Bookmark row title.
  ///
  /// In en, this message translates to:
  /// **'Surah {name} - verse {ayah}'**
  String tafsirBookmarkRef(String name, int ayah);

  /// Empty history state.
  ///
  /// In en, this message translates to:
  /// **'No reading history'**
  String get tafsirNoHistory;

  /// Verse badge.
  ///
  /// In en, this message translates to:
  /// **'Verse {ayah}'**
  String tafsirAyahBadge(int ayah);

  /// Tafsir search hint.
  ///
  /// In en, this message translates to:
  /// **'Search tafsir (root, word, or topic)...'**
  String get tafsirSearchHint;

  /// Minimum-length notice.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 letters for accurate search'**
  String get tafsirMinChars;

  /// No-results state.
  ///
  /// In en, this message translates to:
  /// **'No matching results in this tafsir'**
  String get tafsirNoSearchResults;

  /// Thematic topics header.
  ///
  /// In en, this message translates to:
  /// **'Topics (Thematic Index)'**
  String get tafsirTopicsTitle;

  /// Tips header.
  ///
  /// In en, this message translates to:
  /// **'Search tips:'**
  String get tafsirTipsTitle;

  /// Tip 1.
  ///
  /// In en, this message translates to:
  /// **'Search by word root for broader results.'**
  String get tafsirTipRoot;

  /// Tip 2.
  ///
  /// In en, this message translates to:
  /// **'Search matches text within the currently selected tafsir only.'**
  String get tafsirTipScope;

  /// Search result reference.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah} - verse {ayah}'**
  String tafsirResultRef(int surah, int ayah);

  /// Relative minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String tafsirMinutesAgo(int minutes);

  /// Relative hours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String tafsirHoursAgo(int hours);

  /// Relative days.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String tafsirDaysAgo(int days);

  /// Inline tafsir load error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tafsir'**
  String get tfwLoadError;

  /// Missing-verse-tafsir state.
  ///
  /// In en, this message translates to:
  /// **'No tafsir for this verse'**
  String get tfwNoAyahTafsir;

  /// Full-screen button.
  ///
  /// In en, this message translates to:
  /// **'Full view'**
  String get tfwFullView;

  /// Compare button.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get tfwCompare;

  /// Empty tafsir placeholder.
  ///
  /// In en, this message translates to:
  /// **'No tafsir'**
  String get tfwNoTafsir;

  /// Fullscreen pager label.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah}'**
  String tfwSurahOf(int surah);

  /// Compare sheet title.
  ///
  /// In en, this message translates to:
  /// **'Compare tafsirs'**
  String get tfwCompareTitle;

  /// Sheet header reference.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah} - verse {ayah}'**
  String tfwSheetRef(int surah, int ayah);

  /// Today-stats header.
  ///
  /// In en, this message translates to:
  /// **'Today\'s statistics'**
  String get proTodayStats;

  /// Verses-read stat.
  ///
  /// In en, this message translates to:
  /// **'Verses read'**
  String get proVersesRead;

  /// Reading-time stat.
  ///
  /// In en, this message translates to:
  /// **'Reading time'**
  String get proReadingTime;

  /// Today subtitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get proToday;

  /// Listening stat.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get proListening;

  /// Listening subtitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s verses'**
  String get proListeningToday;

  /// Streak stat.
  ///
  /// In en, this message translates to:
  /// **'Adhkar streak'**
  String get proAdhkarStreak;

  /// Singular day unit.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get proDayOne;

  /// Plural day unit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get proDays;

  /// Adhkar section header.
  ///
  /// In en, this message translates to:
  /// **'Today\'s adhkar'**
  String get proAdhkarToday;

  /// After-prayer count label.
  ///
  /// In en, this message translates to:
  /// **'After prayer'**
  String get proAfterPrayer;

  /// Khatmah section header.
  ///
  /// In en, this message translates to:
  /// **'Khatmah progress'**
  String get proKhatmah;

  /// Khatmah position line.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah} — verse {ayah}'**
  String proKhatmahAt(int surah, int ayah);

  /// Completed-khatmahs line.
  ///
  /// In en, this message translates to:
  /// **'{count} completed khatmahs'**
  String proKhatmahDone(int count);

  /// Weekly header.
  ///
  /// In en, this message translates to:
  /// **'Week summary'**
  String get proWeek;

  /// Listening-time row.
  ///
  /// In en, this message translates to:
  /// **'Listening time'**
  String get proListenTime;

  /// Full-days row.
  ///
  /// In en, this message translates to:
  /// **'Full adhkar days'**
  String get proFullAdhkarDays;

  /// Totals header.
  ///
  /// In en, this message translates to:
  /// **'All-time statistics'**
  String get proTotal;

  /// Total verses unit.
  ///
  /// In en, this message translates to:
  /// **'verses'**
  String get proVerseUnit;

  /// Total reading unit.
  ///
  /// In en, this message translates to:
  /// **'reading'**
  String get proReadUnit;

  /// Total khatmahs unit.
  ///
  /// In en, this message translates to:
  /// **'khatmahs'**
  String get proKhatmahUnit;

  /// Duration seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String proSeconds(int seconds);

  /// Duration minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String proMinutes(int minutes);

  /// Duration hours+minutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String proHoursMinutes(int hours, int minutes);

  /// Permission-denied fallback warning.
  ///
  /// In en, this message translates to:
  /// **'Please enable location permission from settings'**
  String get qiblaPermWarning;

  /// Fallback-location warning.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t locate you; showing the direction from Riyadh'**
  String get qiblaFallbackWarning;

  /// Auto-timeout dialog title.
  ///
  /// In en, this message translates to:
  /// **'Save power'**
  String get qiblaTimeoutTitle;

  /// Auto-timeout dialog body.
  ///
  /// In en, this message translates to:
  /// **'Keep locating the qibla?'**
  String get qiblaTimeoutBody;

  /// Close dialog button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get qiblaClose;

  /// Continue button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get qiblaContinue;

  /// Direction-locked snackbar.
  ///
  /// In en, this message translates to:
  /// **'Qibla direction pinned'**
  String get qiblaLockedSnack;

  /// Pin-removed snackbar.
  ///
  /// In en, this message translates to:
  /// **'Pin removed'**
  String get qiblaUnlockedSnack;

  /// Calibration dialog title.
  ///
  /// In en, this message translates to:
  /// **'Calibrate the compass'**
  String get qiblaCalibTitle;

  /// Calibration intro.
  ///
  /// In en, this message translates to:
  /// **'To improve compass accuracy:'**
  String get qiblaCalibHint;

  /// Calibration step 1.
  ///
  /// In en, this message translates to:
  /// **'1. Move the phone away from metal'**
  String get qiblaCalib1;

  /// Calibration step 2.
  ///
  /// In en, this message translates to:
  /// **'2. Move the phone in a figure 8'**
  String get qiblaCalib2;

  /// Calibration step 3.
  ///
  /// In en, this message translates to:
  /// **'3. Repeat until accuracy improves'**
  String get qiblaCalib3;

  /// Qibla page title.
  ///
  /// In en, this message translates to:
  /// **'Qibla direction'**
  String get qiblaTitle;

  /// Loading state.
  ///
  /// In en, this message translates to:
  /// **'Locating you...'**
  String get qiblaLocating;

  /// Pinned status.
  ///
  /// In en, this message translates to:
  /// **'Pinned direction'**
  String get qiblaLockedBadge;

  /// Pinned short status.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get qiblaPinned;

  /// Calibration tooltip.
  ///
  /// In en, this message translates to:
  /// **'Calibration needed'**
  String get qiblaCalibNeeded;

  /// Kaaba badge.
  ///
  /// In en, this message translates to:
  /// **'Kaaba'**
  String get qiblaKaaba;

  /// Direction info label.
  ///
  /// In en, this message translates to:
  /// **'Qibla direction'**
  String get qiblaDirection;

  /// Distance info label.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get qiblaDistance;

  /// Bearing info label.
  ///
  /// In en, this message translates to:
  /// **'Bearing'**
  String get qiblaBearing;

  /// Pin button.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get qiblaLock;

  /// Unpin button.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get qiblaUnlock;

  /// Skip onboarding button.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get obSkip;

  /// Next button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get obNext;

  /// Finish onboarding button.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get obStart;

  /// Step 1 title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Noor'**
  String get ob1Title;

  /// Step 1 subtitle.
  ///
  /// In en, this message translates to:
  /// **'A complete digital worship space'**
  String get ob1Subtitle;

  /// Step 1 description.
  ///
  /// In en, this message translates to:
  /// **'Quran recitation, hadith memorization, prayer times, and adhkar in one place'**
  String get ob1Desc;

  /// Step 2 title.
  ///
  /// In en, this message translates to:
  /// **'Holy Quran'**
  String get ob2Title;

  /// Step 2 subtitle.
  ///
  /// In en, this message translates to:
  /// **'Recite and reflect'**
  String get ob2Subtitle;

  /// Step 2 description.
  ///
  /// In en, this message translates to:
  /// **'Uthmani-script reading, tafsir, and multiple reciters'**
  String get ob2Desc;

  /// Step 3 title.
  ///
  /// In en, this message translates to:
  /// **'Prophetic hadith'**
  String get ob3Title;

  /// Step 3 subtitle.
  ///
  /// In en, this message translates to:
  /// **'The nine books'**
  String get ob3Subtitle;

  /// Step 3 description.
  ///
  /// In en, this message translates to:
  /// **'Advanced search, topic tree, documentation, and spaced memorization'**
  String get ob3Desc;

  /// Step 4 title.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get ob4Title;

  /// Step 4 subtitle.
  ///
  /// In en, this message translates to:
  /// **'Accurate and smart'**
  String get ob4Subtitle;

  /// Step 4 description.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts, automatic silent mode, and the qibla'**
  String get ob4Desc;

  /// Step 5 title.
  ///
  /// In en, this message translates to:
  /// **'Are you ready?'**
  String get ob5Title;

  /// Step 5 subtitle.
  ///
  /// In en, this message translates to:
  /// **'Begin your spiritual journey'**
  String get ob5Subtitle;

  /// Step 5 description.
  ///
  /// In en, this message translates to:
  /// **'We ask God to make this app beneficial for your faith and life'**
  String get ob5Desc;

  /// Next-prayer badge.
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get npcBadge;

  /// Loading fallback name.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get npcLoading;

  /// Remaining-time line.
  ///
  /// In en, this message translates to:
  /// **'In {remaining}'**
  String npcAfter(String remaining);

  /// Caption under remaining time.
  ///
  /// In en, this message translates to:
  /// **'God willing'**
  String get npcInshallah;

  /// Library title.
  ///
  /// In en, this message translates to:
  /// **'Adhkar library'**
  String get alibTitle;

  /// Review banner.
  ///
  /// In en, this message translates to:
  /// **'Library content under scholarly review'**
  String get alibReviewBanner;

  /// Category count.
  ///
  /// In en, this message translates to:
  /// **'{count} adhkar'**
  String alibCount(int count);

  /// Item source line.
  ///
  /// In en, this message translates to:
  /// **'Source: {ref}'**
  String alibSource(String ref);

  /// Adhkar favorite subtitle.
  ///
  /// In en, this message translates to:
  /// **'Adhkar'**
  String get favAdhkar;

  /// Empty continue-reading title.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get continueStart;

  /// Saved badge.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get continueSaved;

  /// Saved verse line.
  ///
  /// In en, this message translates to:
  /// **'Verse {ayah}'**
  String continueAyah(int ayah);

  /// Empty continue-reading hint.
  ///
  /// In en, this message translates to:
  /// **'Tap to open the mushaf'**
  String get continueGo;

  /// Prayer progress line.
  ///
  /// In en, this message translates to:
  /// **'{done}/5 prayers'**
  String dayTasks(int done);

  /// Streak line.
  ///
  /// In en, this message translates to:
  /// **'{streak} day streak'**
  String dayStreak(int streak);

  /// Adhkar card done title.
  ///
  /// In en, this message translates to:
  /// **'Today\'s portion complete'**
  String get adhkarCardDone;

  /// Adhkar card todo title.
  ///
  /// In en, this message translates to:
  /// **'Keep remembering God'**
  String get adhkarCardTodo;

  /// Adhkar percent line.
  ///
  /// In en, this message translates to:
  /// **'{pct}% complete'**
  String adhkarCardPct(int pct);

  /// Suggestion prefix.
  ///
  /// In en, this message translates to:
  /// **'Smart tip now:'**
  String get sugTipTitle;

  /// Font-size dialog preview label.
  ///
  /// In en, this message translates to:
  /// **'Text preview'**
  String get tfwPreviewText;

  /// Next-prayer tomorrow marker.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get npcTomorrow;

  /// Accessibility label: previous item or page.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get a11yPrevious;

  /// Accessibility label: next item or page.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get a11yNext;

  /// Accessibility label announcing the current tasbih count.
  ///
  /// In en, this message translates to:
  /// **'Count: {count}'**
  String a11yTasbihCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

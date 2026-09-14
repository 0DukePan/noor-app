// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نور';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navQuran => 'القرآن';

  @override
  String get navHadith => 'الحديث';

  @override
  String get navAdhkar => 'الأذكار';

  @override
  String get navTools => 'الأدوات';

  @override
  String get dbImportTitle => 'جارٍ تجهيز قاعدة بيانات الأحاديث...';

  @override
  String get dbImportSubtitle =>
      'سيستغرق التحميل الأول بعض الوقت، ويتم مرة واحدة فقط.';

  @override
  String get appTagline => 'تطبيق إسلامي شامل يخدم بيئة تعبدية رقمية';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get homeLoadError => 'تعذر جلب البيانات';

  @override
  String get homeContinueReading => 'متابعة القراءة';

  @override
  String get homeFavorites => 'المفضلة';

  @override
  String get homeTodayAdhkar => 'أذكار اليوم';

  @override
  String get homePropheticLight => 'نور النبوة';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsHeader => 'تخصيص التطبيق';

  @override
  String get settingsHeaderSubtitle => 'اجعل التطبيق مناسباً لاحتياجاتك';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeSystem => 'تلقائي';

  @override
  String get settingsReading => 'القراءة';

  @override
  String get settingsFontSize => 'حجم الخط';

  @override
  String get settingsGeneral => 'إعدادات عامة';

  @override
  String get settingsHaptics => 'الاهتزاز';

  @override
  String get settingsHapticsSubtitle => 'تفعيل الاستجابة اللمسية عند التفاعل';

  @override
  String get settingsClearCache => 'مسح ذاكرة التخزين';

  @override
  String get settingsClearCacheSubtitle =>
      'حذف البيانات المؤقتة لتحرير المساحة';

  @override
  String get settingsAdvanced => 'إعدادات متقدمة';

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get settingsNotificationsSubtitle =>
      'أذكار الصباح والمساء، تنبيهات الصلاة';

  @override
  String get settingsStorage => 'التخزين والأداء';

  @override
  String get settingsStorageSubtitle => 'إدارة البيانات المحفوظة';

  @override
  String get settingsPrivacy => 'الخصوصية والبيانات';

  @override
  String get settingsPrivacySubtitle => 'لا نجمع أي بيانات شخصية';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get settingsAppName => 'نور';

  @override
  String get settingsAboutBody =>
      'تطبيق إسلامي شامل — القرآن، الحديث، مواقيت الصلاة، الأذكار والتفسير';

  @override
  String settingsAppVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get settingsPrivacyRowOffline =>
      'التطبيق يعمل دون إنترنت للمحتوى الأساسي (القرآن، الحديث، التفسير، الأذكار).';

  @override
  String get settingsPrivacyRowTracking =>
      'لا أدوات تتبع؛ إحصائيات الاستخدام المجهولة مغلقة افتراضياً ولا تُجمع إلا عند تفعيلها. لا نشارك بياناتك مع أي طرف ثالث.';

  @override
  String get settingsPrivacyRowLocation =>
      'يُستخدم موقعك على الجهاز فقط لحساب مواقيت الصلاة واتجاه القبلة، ولا يُرسل لأي خادم.';

  @override
  String get settingsPrivacyRowCrash =>
      'عند حدوث خلل تقني فقط، تُرسل بيانات الخطأ إلى Sentry دون أي معلومات تعريف شخصية.';

  @override
  String get settingsPrivacyRowNotes =>
      'ملاحظاتك الشخصية (محراب التدبر) تُشفَّر وتُحفظ على جهازك فقط.';

  @override
  String get settingsPrivacyRowSync =>
      'لا توجد مزامنة سحابية: كل بياناتك (المحفوظات، الإحصائيات، التقدم) محفوظة محلياً على جهازك.';

  @override
  String get settingsPrivacyRowNetwork =>
      'قد يتصل التطبيق بخوادم عامة لتحميل بيانات مفقودة فقط (تفسير/تلاوة/مواقيت) دون إرسال أي من بياناتك.';

  @override
  String get settingsClearCacheTitle => 'مسح الذاكرة المؤقتة';

  @override
  String get settingsClearCacheBody =>
      'هل أنت متأكد؟ سيتم حذف ذاكرة التلاوة المحملة وفهرس البحث، ويعاد بناؤها تلقائياً عند الحاجة.';

  @override
  String get settingsCancel => 'إلغاء';

  @override
  String get settingsClear => 'مسح';

  @override
  String get settingsCacheCleared => 'تم مسح الذاكرة المؤقتة بنجاح';

  @override
  String get settingsAnalytics => 'إحصائيات الاستخدام';

  @override
  String get settingsAnalyticsOff =>
      'مغلقة افتراضياً — تبقى الأعداد المجهولة على جهازك';

  @override
  String get settingsAnalyticsOn => 'مفعلة — تُجمع أعداد الاستخدام المجهولة';

  @override
  String get settingsAnalyticsPrivacy =>
      'إحصائيات الاستخدام المجهولة: مغلقة افتراضياً؛ وعند تفعيلها تُجمع أعداد إجمالية فقط — لا تُجمع هويتك أو محتواك أبداً.';

  @override
  String get notifTitle => 'الإشعارات';

  @override
  String get notifAdhkarSection => 'تذكيرات الأذكار';

  @override
  String get notifMorning => 'أذكار الصباح';

  @override
  String get notifMorningSubtitle => 'بعد صلاة الفجر بـ 30 دقيقة';

  @override
  String get notifEvening => 'أذكار المساء';

  @override
  String get notifEveningSubtitle => 'قبل صلاة المغرب بـ 30 دقيقة';

  @override
  String get notifPrayerSection => 'إشعارات الصلاة';

  @override
  String get notifBeforePrayer => 'تنبيه قبل الصلاة';

  @override
  String notifBeforeMinutes(int minutes) {
    return 'قبل $minutes دقائق';
  }

  @override
  String get notifBeforeLabel => 'قبل الصلاة بـ';

  @override
  String notifMinutesShort(int minutes) {
    return '$minutes د';
  }

  @override
  String get notifDailySection => 'تذكير القراءة اليومية';

  @override
  String get notifKhatmah => 'تذكير الختمة اليومي';

  @override
  String notifAtTime(String time) {
    return 'الساعة $time';
  }

  @override
  String get notifDisabled => 'معطل';

  @override
  String get notifReminderTime => 'وقت التذكير';

  @override
  String get notifQuietSection => 'ساعات الهدوء';

  @override
  String get notifQuiet => 'ساعات الهدوء';

  @override
  String notifQuietRange(int start, int end) {
    return 'من $start:00 إلى $end:00';
  }

  @override
  String get notifApply => 'تطبيق الإعدادات';

  @override
  String get notifUpdated => '✅ تم تحديث الإشعارات';

  @override
  String get notifKhatmahMessage => 'حان وقت ورد القراءة اليومي';

  @override
  String get storageTitle => 'التخزين والأداء';

  @override
  String get storageCacheSection => 'التخزين المؤقت';

  @override
  String get storageManageSection => 'إدارة البيانات';

  @override
  String get storageSilentSection => 'الواجهة الهادئة';

  @override
  String get storageSurahs => 'سور محفوظة';

  @override
  String get storageHadiths => 'أحاديث محفوظة';

  @override
  String get storageAdhkar => 'أذكار محفوظة';

  @override
  String get storageClearTitle => 'مسح التخزين المؤقت';

  @override
  String get storageClearSubtitle => 'إعادة تحميل البيانات من المصدر';

  @override
  String get storageRefreshTitle => 'تحديث الإحصائيات';

  @override
  String get storageRefreshSubtitle => 'إعادة قراءة البيانات المعروضة';

  @override
  String get storageSilentBody =>
      'تطبيق نور يستخدم واجهة هادئة بدون نوافذ منبثقة مزعجة. جميع الإشعارات تظهر بشكل لطيف وتختفي تلقائيًا.';

  @override
  String get storagePreviewGentle => 'معاينة الإشعار الهادئ';

  @override
  String get storagePreviewSuccess => 'معاينة إشعار النجاح';

  @override
  String get storageGentleSample => '✨ هذا مثال على الإشعار الهادئ';

  @override
  String get storageSavedOk => 'تم الحفظ بنجاح!';

  @override
  String get storageCacheCleared => 'تم مسح التخزين المؤقت';

  @override
  String get storageStatsUpdated => 'تم تحديث الإحصائيات';

  @override
  String get qadaTitle => 'متتبع القضاء';

  @override
  String get qadaTabPrayer => 'الصلاة';

  @override
  String get qadaTabFast => 'الصيام';

  @override
  String get qadaCongrats => '🎉 تهانينا!';

  @override
  String get qadaCongratsBody => 'لقد أتممت قضاء هذا السجل';

  @override
  String get qadaPraiseGod => 'الحمد لله';

  @override
  String get qadaEmptyPrayer => 'لا توجد صلوات فائتة للقضاء';

  @override
  String get qadaEmptyFast => 'لا توجد أيام صيام للقضاء';

  @override
  String get qadaAdd => 'إضافة';

  @override
  String get qadaAddNew => 'إضافة سجل جديد';

  @override
  String qadaProgress(int done, int total) {
    return 'تم: $done من $total';
  }

  @override
  String get qadaComplete => '✓ مكتمل';

  @override
  String qadaRemainingPrayer(int remaining) {
    return 'متبقي: $remaining صلاة';
  }

  @override
  String qadaRemainingFast(int remaining) {
    return 'متبقي: $remaining يوم';
  }

  @override
  String get qadaDidPrayer => 'قضيت صلاة واحدة';

  @override
  String get qadaDidFast => 'صمت يوماً واحداً';

  @override
  String get qadaAddPrayerTitle => 'إضافة صلوات للقضاء';

  @override
  String get qadaAddFastTitle => 'إضافة أيام صيام للقضاء';

  @override
  String get qadaNameLabel => 'الاسم (اختياري)';

  @override
  String get qadaNameHint => 'مثال: صلوات سنة 2020';

  @override
  String get qadaCountLabel => 'العدد *';

  @override
  String get qadaCountPrayerHint => 'عدد الصلوات';

  @override
  String get qadaCountFastHint => 'عدد الأيام';

  @override
  String get qadaNotesLabel => 'ملاحظات (اختياري)';

  @override
  String get qadaNotesHint => 'أي ملاحظات إضافية';

  @override
  String get qadaInvalidCount => 'الرجاء إدخال عدد صحيح';

  @override
  String get qadaDefaultPrayerName => 'صلوات قضاء';

  @override
  String get qadaDefaultFastName => 'أيام صيام';

  @override
  String get prayerTitle => 'مواقيت الصلاة';

  @override
  String get prayerQadaTooltip => 'قضاء الصلوات';

  @override
  String get prayerLoadError => 'تعذر تحميل أوقات الصلاة';

  @override
  String get prayerDayDone => 'انتهت صلوات اليوم';

  @override
  String prayerNext(String name) {
    return 'الصلاة القادمة: $name';
  }

  @override
  String get prayerUntilAdhan => 'متبقي حتى الأذان';

  @override
  String get psetTitle => 'إعدادات الصلاة';

  @override
  String get psetAdhanSection => 'الأذان والتنبيهات';

  @override
  String get psetMosqueSection => 'وضع المسجد';

  @override
  String get psetMethodSection => 'طريقة حساب المواقيت';

  @override
  String get psetOffsetsSection => 'الإزاحات الموسمية';

  @override
  String get psetHealthSection => 'فحص النظام';

  @override
  String get psetMethodHint => 'الطريقة المستخدمة لحساب جميع المواقيت';

  @override
  String get psetAdhanOn => 'الأذان مفعل';

  @override
  String get psetAdhanOff => 'الأذان معطل';

  @override
  String get psetMosque => 'وضع المسجد';

  @override
  String get psetMosqueOn => 'يتم كتم الهاتف تلقائيًا عند وقت الصلاة';

  @override
  String get psetMosqueOff => 'معطل — يدوي فقط';

  @override
  String get psetDuration => 'المدة';

  @override
  String psetDurationMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get psetQuick => 'تفعيل سريع';

  @override
  String get psetQuick10 => '🕌 وضع المسجد — 10 دقائق';

  @override
  String get psetQuick20 => '🕌 وضع المسجد — 20 دقيقة';

  @override
  String get psetQuick30 => '🕌 وضع المسجد — 30 دقيقة';

  @override
  String get psetReset => 'إعادة تعيين';

  @override
  String get psetHealthRun => 'تشغيل فحص النظام';

  @override
  String get psetHealthRunning => 'جاري الفحص...';

  @override
  String get psetAllGood => 'كل شيء يعمل بشكل ممتاز!';

  @override
  String get psetFix => 'إصلاح';

  @override
  String get psetBadgeHealthy => 'النظام سليم';

  @override
  String get psetBadgeWarning => 'يوجد تحذيرات';

  @override
  String get psetBadgeCritical => 'يوجد مشاكل حرجة';

  @override
  String get tasbihTitle => 'المسبحة الإلكترونية';

  @override
  String get tasbihReset => 'تصفير';

  @override
  String get tasbihPreset33 => '٣٣';

  @override
  String get tasbihPreset100 => '١٠٠';

  @override
  String get tasbihOpen => 'مفتوح';

  @override
  String get tasbihHint => 'اضغط في أي مكان للشاشة للعد';

  @override
  String get toolsTitle => 'الأدوات';

  @override
  String get toolsPrayer => 'مواقيت الصلاة';

  @override
  String get toolsPrayerSub => 'الأوقات والتنبيهات';

  @override
  String get toolsQibla => 'القبلة';

  @override
  String get toolsQiblaSub => 'اتجاه القبلة';

  @override
  String get toolsTasbih => 'المسبحة';

  @override
  String get toolsTasbihSub => 'عداد التسبيح';

  @override
  String get toolsSearch => 'البحث';

  @override
  String get toolsSearchSub => 'البحث في القرآن والحديث';

  @override
  String get toolsHifz => 'الحفظ والمراجعة';

  @override
  String get toolsHifzSub => 'حفظ الآيات ومراجعتها';

  @override
  String get toolsProfile => 'ملفي الشخصي';

  @override
  String get toolsProfileSub => 'الإحصائيات والتقدم';

  @override
  String get toolsSettingsSub => 'الإعدادات العامة والمظهر';

  @override
  String audioTitle(String name) {
    return 'سورة $name';
  }

  @override
  String get audioResumeTitle => 'استئناف التلاوة؟';

  @override
  String audioResumeBody(String surah, int ayah) {
    return 'هل تريد متابعة التلاوة من سورة $surah - الآية $ayah؟';
  }

  @override
  String get audioNo => 'لا';

  @override
  String get audioResume => 'استئناف';

  @override
  String audioAyahOf(int ayah, int total) {
    return 'الآية $ayah من $total';
  }

  @override
  String get audioPickSurah => 'اختر السورة';

  @override
  String get audioPickReciter => 'اختر القارئ';

  @override
  String audioLoadError(String error) {
    return 'خطأ في تحميل السورة: $error';
  }

  @override
  String get audioNowPlaying => 'يُتلى الآن';

  @override
  String get mushafEmpty => 'صفحة فارغة';

  @override
  String mushafError(String error) {
    return 'خطأ: $error';
  }

  @override
  String mushafJuz(int juz) {
    return 'الجزء $juz';
  }

  @override
  String get mushafAppearanceTooltip => 'المظهر';

  @override
  String mushafPageIndicator(int page) {
    return 'صفحة $page / 604';
  }

  @override
  String get mushafCopy => 'نسخ';

  @override
  String get mushafSave => 'حفظ';

  @override
  String get mushafSaved => 'تم حفظ العلامة 🔖';

  @override
  String get mushafShareCopied => 'تم النسخ للمشاركة';

  @override
  String get mushafTafsirTitle => 'التفسير الميسر';

  @override
  String get mushafTafsirMissing => 'التفسير غير متوفر حالياً';

  @override
  String get mushafReadMore => 'اقرأ المزيد ←';

  @override
  String get mushafOpenFull => 'فتح التفسير الكامل';

  @override
  String mushafAyahLabel(String name, int ayah) {
    return '$name ﴿$ayah﴾';
  }

  @override
  String mushafShareTemplate(String verse, String surah, int ayah) {
    return '$verse\n\n— $surah ﴿$ayah﴾';
  }

  @override
  String get surahLoadError => 'حدث خطأ في تحميل السورة';

  @override
  String surahFallback(int number) {
    return 'سورة $number';
  }

  @override
  String get surahKhushuTooltip => 'وضع الخشوع';

  @override
  String get surahListenTooltip => 'استماع';

  @override
  String get surahAppearance => 'مظهر القراءة';

  @override
  String get surahShowTranslation => 'إظهار الترجمة';

  @override
  String get surahTrLang => 'لغة الترجمة:';

  @override
  String get verseTafsir => 'تفسير الآية';

  @override
  String get verseAddHifz => 'أضف للحفظ';

  @override
  String get verseHifzAdded => 'أُضيفت الآية لبطاقات الحفظ';

  @override
  String get verseAddBookmark => 'إضافة علامة';

  @override
  String get verseBookmarkSaved => 'تم حفظ العلامة';

  @override
  String get verseShare => 'مشاركة';

  @override
  String get verseShareCopied => 'تم نسخ الآية للمشاركة';

  @override
  String get versePlayAudio => 'تشغيل الصوت';

  @override
  String get verseCopy => 'نسخ الآية';

  @override
  String get verseCopied => 'تم نسخ الآية';

  @override
  String verseShareTemplate(String verse, int surah, int ayah) {
    return '$verse\n\n— القرآن الكريم (سورة $surah، آية $ayah)';
  }

  @override
  String get quranTitle => 'القرآن الكريم';

  @override
  String quranSurahCount(int count) {
    return '$count سورة';
  }

  @override
  String get quranContinue => 'متابعة القراءة';

  @override
  String quranSurahNumber(String number) {
    return 'سورة رقم $number';
  }

  @override
  String get quranNoResults => 'لا توجد نتائج';

  @override
  String get quranMushaf => 'المصحف';

  @override
  String get quranKhatmahPlan => 'خطة الختمة';

  @override
  String get quranTafsir => 'التفسير';

  @override
  String get quranFilterAll => 'الكل';

  @override
  String get quranMeccan => 'مكية';

  @override
  String get quranMedinan => 'مدنية';

  @override
  String get quranSearchHint => 'ابحث عن سورة...';

  @override
  String quranAyahCount(int count) {
    return '$count آية';
  }

  @override
  String get quranError => 'حدث خطأ';

  @override
  String get khatmahTitle => 'خطة الختمة';

  @override
  String get khatmahEmpty => 'لا توجد ختمة نشطة';

  @override
  String get khatmahStart => 'بدء ختمة جديدة';

  @override
  String get khatmahSchedule => 'جدول القراءة';

  @override
  String get khatmahHistory => 'ختماتك السابقة';

  @override
  String get khatmahNoneDone => 'لم تُتمم أي ختمة بعد';

  @override
  String get khatmahActive => 'نشطة';

  @override
  String khatmahPageOfTotal(int current, int total) {
    return 'صفحة $current من $total';
  }

  @override
  String get khatmahLastPosition => 'آخر موضع';

  @override
  String khatmahPositionAt(String surah, int ayah) {
    return 'سورة $surah - آية $ayah';
  }

  @override
  String get khatmahResume => 'متابعة';

  @override
  String khatmahGoal(String date) {
    return 'الهدف: $date';
  }

  @override
  String get khatmahDailyGoal => 'هدف اليوم';

  @override
  String khatmahPagesToday(int read, int need) {
    return '$read / $need صفحة';
  }

  @override
  String get khatmahGoalDone => '🎉 أحسنت! أتممت هدف اليوم';

  @override
  String khatmahSchedulePages(String pages) {
    return 'صفحات $pages';
  }

  @override
  String khatmahDoneIn(int days) {
    return 'أتممتها في $days يوم';
  }

  @override
  String get khatmahNew => 'ختمة جديدة';

  @override
  String get khatmahNameHint => 'اسم الختمة (اختياري)';

  @override
  String get khatmahDuration => 'المدة:';

  @override
  String khatmahDaysOption(int days) {
    return '$days يوم';
  }

  @override
  String khatmahPerDay(int pages) {
    return '≈ $pages صفحة يومياً';
  }

  @override
  String get khatmahStartButton => 'ابدأ الختمة';

  @override
  String get tadTitle => 'محراب التدبر';

  @override
  String get tadSaved => 'تم حفظ ملاحظتك بشكل آمن 🔒';

  @override
  String tadRef(int surah, int ayah) {
    return 'سورة $surah - آية $ayah';
  }

  @override
  String get tadHint => 'اكتب تدبرك وخواطرك هنا...';

  @override
  String get tadEncrypted => '🔒 ملاحظاتك مشفرة محلياً';

  @override
  String get tadSave => 'حفظ';

  @override
  String get tadPrevious => 'ملاحظاتك السابقة';

  @override
  String get tadEmpty => 'لا توجد ملاحظات بعد';

  @override
  String get tadPrivacyTitle => 'خصوصية ملاحظاتك';

  @override
  String get tadPrivacy1 => '🔒 ملاحظاتك مشفرة محلياً على جهازك';

  @override
  String get tadPrivacy2 => '☁️ لا يتم رفعها للسحابة أبداً';

  @override
  String get tadPrivacy3 => '👁️ لا أحد يستطيع قراءتها سواك';

  @override
  String get tadPrivacyAes => 'تستخدم تشفير AES-256 لحماية أفكارك.';

  @override
  String get tadGotIt => 'فهمت';

  @override
  String get topicTitle => 'التصنيف الموضوعي';

  @override
  String get topicEmpty => 'لا توجد مواضيع بعد';

  @override
  String get topicEmptyHint => 'يتم بناء الفهرس عند أول تحميل للأحاديث';

  @override
  String topicHadithCount(int count) {
    return '$count حديث';
  }

  @override
  String get memTitle => 'حفظ الأحاديث';

  @override
  String get memDueToday => 'متبقي اليوم';

  @override
  String get memReviewedToday => 'راجعت اليوم';

  @override
  String get memTotal => 'إجمالي الحفظ';

  @override
  String get memHintFallback => 'قال رسول الله ﷺ: \"…';

  @override
  String get memRemember => 'تذكّر الحديث...';

  @override
  String get memShowAnswer => 'اضغط لإظهار الإجابة';

  @override
  String get memDayFallback => '1 يوم';

  @override
  String get memDone => 'أحسنت! أنهيت مراجعة اليوم';

  @override
  String get memComeBack => 'عد غداً لمواصلة الحفظ';

  @override
  String get memBack => 'العودة';

  @override
  String get lstatsTitle => 'إحصائياتي';

  @override
  String get lstatsBookmarks => 'محفوظات';

  @override
  String get lstatsHadithUnit => 'حديث';

  @override
  String get lstatsNotes => 'ملاحظات';

  @override
  String get lstatsNoteUnit => 'ملاحظة';

  @override
  String get lstatsQuizzes => 'اختبارات';

  @override
  String lstatsQuizAvg(int score) {
    return '$score% متوسط';
  }

  @override
  String get lstatsMemorize => 'حفظ';

  @override
  String get lstatsCardUnit => 'بطاقة';

  @override
  String get lstatsWeekActivity => 'نشاط الأسبوع';

  @override
  String get lstatsByBooks => 'المحفوظات حسب الكتب';

  @override
  String get lstatsStreak => 'سلسلة الأيام';

  @override
  String lstatsLongest(int days) {
    return 'أطول سلسلة: $days يوم';
  }

  @override
  String lstatsBookSaved(int read) {
    return '$read محفوظ';
  }

  @override
  String hifzStreakLine(String emoji) {
    return '$emoji سلسلة الممارسة';
  }

  @override
  String hifzDays(int count) {
    return '$count يوم';
  }

  @override
  String get hifzToMemorize => 'للحفظ';

  @override
  String get hifzToReview => 'للمراجعة';

  @override
  String hifzStartReview(int count) {
    return 'بدء المراجعة ($count)';
  }

  @override
  String hifzStartNew(int count) {
    return 'بدء حفظ $count آية جديدة';
  }

  @override
  String get hifzEmpty => 'أضف آيات من صفحة السورة\nلتبدأ رحلة الحفظ';

  @override
  String hifzMyCards(int count) {
    return 'بطاقاتي ($count)';
  }

  @override
  String hifzCardRef(int surah, int ayah) {
    return 'سورة $surah : آية $ayah';
  }

  @override
  String get hifzNew => 'جديدة';

  @override
  String get hifzDueToday => 'مستحقة اليوم';

  @override
  String hifzAfterDays(int days) {
    return 'بعد $days يوم';
  }

  @override
  String get hifzRepeat => 'التكرار: ';

  @override
  String get searchHintUnified => 'ابحث في القرآن والحديث...';

  @override
  String get searchPrompt => 'ابحث عن آية أو حديث';

  @override
  String get searchBadgeHadith => 'الحديث الشريف';

  @override
  String get searchBadgeAdhkar => 'الأذكار';

  @override
  String searchQuranRef(String surah, String verse) {
    return 'سورة $surah : آية $verse';
  }

  @override
  String get searchCopied => 'تم نسخ النص';

  @override
  String get hsearchTitle => 'البحث المتقدم';

  @override
  String get hsearchAllBooks => 'جميع الكتب';

  @override
  String get hsearchButton => 'بحث';

  @override
  String get hsearchEmpty => 'ابحث في الكتب التسعة';

  @override
  String get hsearchEmptySub => 'البحث يشمل النص العربي والإنجليزي';

  @override
  String get hsearchNoResults => 'لم يتم العثور على نتائج';

  @override
  String hsearchCount(int count) {
    return '$count نتيجة';
  }

  @override
  String get hsearchByText => 'بحث بالنص';

  @override
  String get hsearchByNarrator => 'بحث بالراوي';

  @override
  String get hsearchTextHint => 'ابحث بكلمة أو عبارة...';

  @override
  String get hsearchNarratorHint => 'اسم الراوي بالإنجليزية...';

  @override
  String hsearchHadithNumber(int id) {
    return 'حديث رقم $id';
  }

  @override
  String get hsessionDoneTitle => 'ما شاء الله 🎉';

  @override
  String get hsessionDoneBody =>
      'أتممت الجلسة بنجاح. استمر في الممارسة اليومية لتثبيت الحفظ.';

  @override
  String get hsessionFinish => 'إنهاء';

  @override
  String hsessionCounter(int index, int total) {
    return 'جلسة حفظ ($index/$total)';
  }

  @override
  String hsessionCardRef(int surah, int ayah) {
    return 'سورة $surah — آية $ayah';
  }

  @override
  String hsessionRepeatCount(int count) {
    return 'التكرار ×$count';
  }

  @override
  String get hsessionRatePrompt => 'كيف كان تذكُّرُك؟';

  @override
  String hsessionIntervalDays(int days) {
    return '$days يوم';
  }

  @override
  String get hpageTitle => 'جوامع الكلم';

  @override
  String get hpageSubtitle => 'مكتبة السنة النبوية الشريفة';

  @override
  String get hpageBookmarksTooltip => 'المحفوظات';

  @override
  String get hpageQuizTooltip => 'اختبار الحديث';

  @override
  String get hpageBooks => 'الكتب والمجاميع';

  @override
  String get hpageBooksHint => 'اختر كتاباً لتصفح الأحاديث';

  @override
  String get hpageBookCollection => 'مجموعة أحاديث';

  @override
  String hpageError(String error) {
    return 'حدث خطأ: $error';
  }

  @override
  String get hpageStudyTools => 'أدوات الدراسة';

  @override
  String get hpageToolMemorize => 'الحفظ بالتكرار';

  @override
  String get hpageToolStats => 'الإحصائيات';

  @override
  String get hpageToolTags => 'الوسوم';

  @override
  String get hpageToolTopics => 'شجرة المواضيع';

  @override
  String get hpageToolAdvanced => 'المتصفح المتقدم';

  @override
  String get hpageContinue => 'مواصلة القراءة';

  @override
  String hpageContinueAt(String title, int index, int total) {
    return '$title  •  حديث $index / $total';
  }

  @override
  String get hpageToday => 'حديث اليوم';

  @override
  String get hpageReadMore => 'اقرأ المزيد';

  @override
  String get hbmRemoved => 'تمت إزالة الحديث من المحفوظات';

  @override
  String get hbmEmpty => 'لا توجد أحاديث محفوظة';

  @override
  String get hbmEmptyHint => 'اضغط على أيقونة الحفظ أثناء قراءة الحديث';

  @override
  String get tagsNew => 'إنشاء وسم جديد';

  @override
  String get tagsNameHint => 'اسم الوسم (مثال: للمراجعة)';

  @override
  String get tagsIcon => 'الأيقونة';

  @override
  String get tagsColor => 'اللون';

  @override
  String get tagsCreate => 'إنشاء';

  @override
  String get tagsTitle => 'وسوماتي';

  @override
  String get tagsEmpty => 'لا توجد وسومات بعد';

  @override
  String get tagsEmptyHint => 'أنشئ وسوماً لتنظيم أحاديثك المفضلة';

  @override
  String get tagsNewFab => 'وسم جديد';

  @override
  String get tagsRemoved => 'تمت إزالة الحديث من الوسم';

  @override
  String get tagsAdded => 'تمت إضافة الحديث إلى الوسم ✓';

  @override
  String get cmpTitle => 'مقارنة الروايات';

  @override
  String get cmpDiffTooltip => 'إظهار الفروقات';

  @override
  String get cmpSideBySide => 'عرض جنباً إلى جنب';

  @override
  String get cmpEmpty => 'لم يتم العثور على روايات مطابقة';

  @override
  String get cmpEmptyHint => 'حاول بكلمة مفتاحية مختلفة';

  @override
  String get cmpUngraded => 'غير محكوم';

  @override
  String cmpDiffCount(int count) {
    return '$count اختلاف';
  }

  @override
  String get cmpSideTitle => 'مقارنة جنباً إلى جنب';

  @override
  String get quizComplete => 'أكمل الحديث';

  @override
  String get quizChoose => 'اختر الصحيح';

  @override
  String get quizNarrator => 'حدد الراوي';

  @override
  String get quizGrade => 'درجة الحديث';

  @override
  String quizQuestion(int index, int total) {
    return 'السؤال $index من $total';
  }

  @override
  String get quizPassed => 'أحسنت!';

  @override
  String get quizFailed => 'حاول مرة أخرى';

  @override
  String quizScore(int score, int total) {
    return '$score من $total إجابات صحيحة';
  }

  @override
  String get quizRetry => 'إعادة الاختبار';

  @override
  String get hchLoading => 'جارٍ تحميل الأبواب...';

  @override
  String get hchError => 'حدث خطأ أثناء تحميل الكتاب';

  @override
  String hchChapters(int count) {
    return '$count باب';
  }

  @override
  String get hchAllTitle => 'جميع الأحاديث';

  @override
  String get hchViewAll => 'عرض جميع الأحاديث';

  @override
  String get hchSection => 'الأبواب';

  @override
  String get hchHadithUnit => 'حديث';

  @override
  String get hchEmpty => 'لا توجد أحاديث في هذا الباب';

  @override
  String get igTitle => 'الرسم البياني للإسناد';

  @override
  String igCount(int count) {
    return '$count راوٍ';
  }

  @override
  String get igLoading => 'جارٍ تحليل الإسناد...';

  @override
  String get igEmpty => 'لم يتم العثور على إسناد';

  @override
  String get ichainTitle => 'سلسلة الإسناد';

  @override
  String get ichainGraphTooltip => 'عرض الرسم البياني';

  @override
  String get ichainLoading => 'جاري تحليل سلسلة الإسناد...';

  @override
  String get ichainEmptyHint =>
      'لا يحتوي نص الحديث على سلسلة إسناد قابلة للتحليل';

  @override
  String ichainCount(int count) {
    return '$count رواة في السلسلة';
  }

  @override
  String get ichainCardTitle => 'بطاقة الراوي';

  @override
  String get hreaderBookmarked => 'تمت إضافة الحديث للمحفوظات';

  @override
  String get hreaderCopied => 'تم نسخ الحديث';

  @override
  String hreaderCopyTemplate(
      String text, String title, int id, String narrator) {
    return '$text\n\n$narrator\n\n— $title #$id';
  }

  @override
  String hreaderTitle(String title, int id) {
    return '$title — #$id';
  }

  @override
  String get hreaderSharahTooltip => 'شرح';

  @override
  String hreaderNumberBadge(int id) {
    return 'حديث #$id';
  }

  @override
  String get hreaderPrev => 'السابق';

  @override
  String get hreaderNext => 'التالي';

  @override
  String get hshareTitle => 'مشاركة كصورة';

  @override
  String get hshareNow => 'مشاركة الآن';

  @override
  String get hshareProcessing => 'جاري التجهيز...';

  @override
  String hshareText(String title, int id) {
    return '📖 $title - حديث رقم $id\n\nتطبيق نور الإسلامي';
  }

  @override
  String hshareError(String error) {
    return 'حدث خطأ أثناء حفظ الصورة: $error';
  }

  @override
  String get schTitle => 'وضع طالب العلم';

  @override
  String get schHighlightTooltip => 'تظليل الكلمات المهمة';

  @override
  String get schShareTooltip => 'مشاركة مع التخريج';

  @override
  String get schUngraded => 'غير محكوم';

  @override
  String schHadithNumber(int number) {
    return 'الحديث رقم $number';
  }

  @override
  String get schTakhrij => 'التخريج';

  @override
  String get schBook => 'الكتاب';

  @override
  String get schChapter => 'الباب';

  @override
  String schChapterValue(int chapter) {
    return 'الباب $chapter';
  }

  @override
  String get schNumber => 'رقم الحديث';

  @override
  String get schCompanion => 'الصحابي';

  @override
  String get schTopics => 'المواضيع';

  @override
  String get schNotes => 'ملاحظاتي';

  @override
  String get schNotesHint => 'أضف ملاحظاتك على هذا الحديث...';

  @override
  String get schNotesSaved => 'تُحفظ الملاحظات تلقائيًا';

  @override
  String get schSimilar => 'أحاديث مشابهة';

  @override
  String get schNoSimilar => 'لا توجد أحاديث مشابهة';

  @override
  String get schNoIsnad => 'لم يتم العثور على إسناد في هذا الحديث';

  @override
  String get schIsnadAnalysis => 'تحليل الإسناد';

  @override
  String schChainCount(int count) {
    return '$count راوٍ في السلسلة';
  }

  @override
  String get schStatNarrators => 'الرواة';

  @override
  String get schStatCompanions => 'الصحابة';

  @override
  String get schStatProphet => 'النبي ﷺ';

  @override
  String schChainConnected(int count) {
    return 'سلسلة متصلة ($count حلقات)';
  }

  @override
  String schChainShort(int count) {
    return 'سلسلة قصيرة ($count حلقات)';
  }

  @override
  String get schCopyTakhrij => 'نسخ مع التخريج';

  @override
  String get schSaveReview => 'حفظ للمراجعة';

  @override
  String get schCopiedTakhrij => 'تم النسخ مع التخريج ✓';

  @override
  String get schAddedReview => 'تمت الإضافة للمراجعة ✓';

  @override
  String schTakhrijBook(String book) {
    return '📚 $book';
  }

  @override
  String schTakhrijChapter(int chapter, int number) {
    return '📖 الباب $chapter - الحديث $number';
  }

  @override
  String schTakhrijGrade(String grade) {
    return '✓ $grade';
  }

  @override
  String schTakhrijCompanion(String companion) {
    return '👤 $companion';
  }

  @override
  String get schTakhrijApp => '— تطبيق نور الإسلامي';

  @override
  String get advTabSearch => 'بحث';

  @override
  String get advTabCompanions => 'الصحابة';

  @override
  String get advTabTopics => 'المواضيع';

  @override
  String get advTabBooks => 'الكتب';

  @override
  String get advSearchHint => 'اكتب نصاً للبحث...';

  @override
  String get advScope => 'نطاق البحث:';

  @override
  String get advFilterMatn => 'المتن';

  @override
  String get advFilterSanad => 'السند';

  @override
  String get advFilterBooks => 'تصفية بالكتب';

  @override
  String get advMode => 'وضع البحث:';

  @override
  String get advModeSmart => 'ذكي';

  @override
  String get advModeAny => 'أي كلمة';

  @override
  String get advModeAll => 'كل الكلمات';

  @override
  String get advModePhrase => 'عبارة';

  @override
  String get advModeRoot => 'بالجذر';

  @override
  String get advNarratorHint => 'راوٍ في السند...';

  @override
  String get advFromHint => 'من';

  @override
  String get advToHint => 'إلى';

  @override
  String get advGrade => 'الحكم:';

  @override
  String get advEmptyTitle => 'الموسوعة الحديثية';

  @override
  String get advEmptyBody =>
      'يمكنك البحث في آلاف الأحاديث النبوية\nمن الكتب التسعة المعتمدة';

  @override
  String get advAllBooksOption => 'كل الكتب';

  @override
  String advRangeBoth(int from, int to) {
    return 'رقم $from - $to';
  }

  @override
  String advRangeFrom(int from) {
    return 'رقم ≥ $from';
  }

  @override
  String advRangeTo(int to) {
    return 'رقم ≤ $to';
  }

  @override
  String advMatchScore(String score) {
    return 'تطابق $score%';
  }

  @override
  String advBookNumber(String book, int number) {
    return '$book - $number';
  }

  @override
  String get layScholarTooltip => 'وضع طالب العلم';

  @override
  String get layTabMatn => 'المتن';

  @override
  String get layTabSanad => 'السند';

  @override
  String get layTabHukm => 'الحكم';

  @override
  String get layCopyMatn => 'نسخ المتن';

  @override
  String get layChainTitle => 'سلسلة الرواة';

  @override
  String get layFullSanad => 'السند الكامل';

  @override
  String get layCompanionRaa => 'الصحابي رضي الله عنه';

  @override
  String get layGradeGuide => 'دليل الأحكام';

  @override
  String layChapterOf(int chapter) {
    return 'الباب $chapter';
  }

  @override
  String layHadithOf(int number) {
    return 'الحديث رقم $number';
  }

  @override
  String get layOtherBooks => 'الحديث في كتب أخرى';

  @override
  String get layNotInOthers => 'لم يُوجد في كتب أخرى';

  @override
  String laySimilarNumber(int number) {
    return 'الحديث $number';
  }

  @override
  String get layCopyTakhrij => 'نسخ التخريج الكامل';

  @override
  String get layCopied => 'تم النسخ ✓';

  @override
  String layTakhrijNumber(int number) {
    return '🔢 الحديث $number';
  }

  @override
  String layTakhrijChapter(int chapter) {
    return '📖 الباب $chapter';
  }

  @override
  String layTakhrijGrade(String grade) {
    return '⚖️ الحكم: $grade';
  }

  @override
  String layTakhrijCompanion(String companion) {
    return '👤 الصحابي: $companion';
  }

  @override
  String sharhTitle(int id) {
    return 'شرح الحديث #$id';
  }

  @override
  String get sharhMatn => 'متن الحديث';

  @override
  String get sharhTakhrij => 'التخريج والدرجة';

  @override
  String get sharhBook => 'الكتاب';

  @override
  String get sharhNumber => 'رقم الحديث';

  @override
  String get sharhNarrator => 'الراوي';

  @override
  String get sharhSource => 'المصدر';

  @override
  String get sharhBenefits => 'فوائد الحديث';

  @override
  String get sharhNotes => 'ملاحظاتي';

  @override
  String get sharhNotesHint => 'اكتب ملاحظاتك وتأملاتك هنا...';

  @override
  String get sharhNoteSaved => '✅ تم حفظ الملاحظة';

  @override
  String get sharhSimilar => 'أحاديث مشابهة';

  @override
  String get sharhTools => 'أدوات دراسية';

  @override
  String get sharhIsnadMap => 'خريطة الإسناد';

  @override
  String get sharhIsnadMapSub => 'سلسلة رواة الحديث';

  @override
  String get sharhIsnadGraphSub => 'عرض تفاعلي لسلسلة الرواة';

  @override
  String get sharhCompare => 'مقارنة الروايات';

  @override
  String get sharhCompareSub => 'ألفاظ مختلفة للحديث في كتب متعددة';

  @override
  String get sharhAddTag => 'إضافة إلى وسم';

  @override
  String get sharhAddTagSub => 'تنظيم الحديث في قوائمك الخاصة';

  @override
  String get adhkarTitle => 'الأذكار اليومية';

  @override
  String adhkarStreakDays(int count) {
    return '$count يوم';
  }

  @override
  String get adhkarMorning => 'أذكار الصباح';

  @override
  String get adhkarEvening => 'أذكار المساء';

  @override
  String get adhkarAfterPrayer => 'بعد الصلاة';

  @override
  String get adhkarSleep => 'أذكار النوم';

  @override
  String get adhkarWakeup => 'الاستيقاظ';

  @override
  String get adhkarQuranic => 'أدعية قرآنية';

  @override
  String get adhkarLibrary => 'مكتبة الأذكار';

  @override
  String get adhkarLibrarySub => 'أكثر من ١٠٠ ذكر بمصادرها';

  @override
  String get adhkarUnitZekr => 'ذكر';

  @override
  String get adhkarUnitDua => 'دعاء';

  @override
  String get adhkarTodayDone => 'أحسنت! أكملت ورد اليوم';

  @override
  String get adhkarToday => 'ورد اليوم';

  @override
  String get adhkarChipMorning => 'الصباح';

  @override
  String get adhkarChipEvening => 'المساء';

  @override
  String get adhkarBlessed => 'بارك الله فيك';

  @override
  String adhkarRemainingJoined(String list) {
    return 'تبقى: $list';
  }

  @override
  String get adhkarAllDone => 'أكملت أذكار اليوم!';

  @override
  String adhkarCongratsBody(String name) {
    return 'أكملت $name';
  }

  @override
  String get adhkarDone => 'تم';

  @override
  String get adhkarNoAdhkar => 'لا توجد أذكار';

  @override
  String get adhkarBlessAccept => 'بارك الله فيك وتقبل منك';

  @override
  String get adhkarBackToList => 'العودة للقائمة';

  @override
  String adhkarOfTotal(int total) {
    return 'من $total';
  }

  @override
  String get tafsirPickTooltip => 'اختر التفسير';

  @override
  String get tafsirTabBookmarks => 'العلامات';

  @override
  String get tafsirTabHistory => 'السجل';

  @override
  String get tafsirSurahLabel => 'السورة';

  @override
  String get tafsirNoTafsir => 'لا يوجد تفسير لهذه السورة';

  @override
  String get tafsirNoBookmarks => 'لا توجد علامات محفوظة';

  @override
  String tafsirBookmarkRef(String name, int ayah) {
    return 'سورة $name - الآية $ayah';
  }

  @override
  String get tafsirNoHistory => 'لا يوجد سجل قراءة';

  @override
  String tafsirAyahBadge(int ayah) {
    return 'الآية $ayah';
  }

  @override
  String get tafsirSearchHint => 'ابحث في التفسير (جذر، كلمة، أو موضوع)...';

  @override
  String get tafsirMinChars => 'أدخل 3 حروف على الأقل للبحث بدقة';

  @override
  String get tafsirNoSearchResults => 'لم نعثر على نتائج مطابقة في هذا التفسير';

  @override
  String get tafsirTopicsTitle => 'الموضوعات والتصنيفات (Thematic Index)';

  @override
  String get tafsirTipsTitle => 'نصائح للبحث:';

  @override
  String get tafsirTipRoot =>
      'يمكنك البحث عن جذر الكلمة للحصول على نتائج أشمل.';

  @override
  String get tafsirTipScope =>
      'البحث يطابق النص ضمن التفسير المختار حالياً فقط.';

  @override
  String tafsirResultRef(int surah, int ayah) {
    return 'سورة $surah • الآية $ayah';
  }

  @override
  String tafsirMinutesAgo(int minutes) {
    return 'منذ $minutes دقيقة';
  }

  @override
  String tafsirHoursAgo(int hours) {
    return 'منذ $hours ساعة';
  }

  @override
  String tafsirDaysAgo(int days) {
    return 'منذ $days يوم';
  }

  @override
  String get tfwLoadError => 'فشل في تحميل التفسير';

  @override
  String get tfwNoAyahTafsir => 'لا يوجد تفسير لهذه الآية';

  @override
  String get tfwFullView => 'عرض كامل';

  @override
  String get tfwCompare => 'مقارنة';

  @override
  String get tfwNoTafsir => 'لا يوجد تفسير';

  @override
  String tfwSurahOf(int surah) {
    return 'سورة $surah';
  }

  @override
  String get tfwCompareTitle => 'مقارنة التفاسير';

  @override
  String tfwSheetRef(int surah, int ayah) {
    return 'سورة $surah - الآية $ayah';
  }

  @override
  String get proTodayStats => '📊 إحصائيات اليوم';

  @override
  String get proVersesRead => 'آيات مقروءة';

  @override
  String get proReadingTime => 'وقت القراءة';

  @override
  String get proToday => 'اليوم';

  @override
  String get proListening => 'الاستماع';

  @override
  String get proListeningToday => 'آيات اليوم';

  @override
  String get proAdhkarStreak => 'سلسلة الأذكار';

  @override
  String get proDayOne => 'يوم';

  @override
  String get proDays => 'أيام';

  @override
  String get proAdhkarToday => '🤲 أذكار اليوم';

  @override
  String get proAfterPrayer => 'بعد الصلاة';

  @override
  String get proKhatmah => '📖 تقدم الختمة';

  @override
  String proKhatmahAt(int surah, int ayah) {
    return 'السورة $surah — الآية $ayah';
  }

  @override
  String proKhatmahDone(int count) {
    return '$count ختمات مكتملة';
  }

  @override
  String get proWeek => '📈 ملخص الأسبوع';

  @override
  String get proListenTime => 'وقت الاستماع';

  @override
  String get proFullAdhkarDays => 'أيام أذكار كاملة';

  @override
  String get proTotal => '🏆 الإحصائيات الكلية';

  @override
  String get proVerseUnit => 'آية';

  @override
  String get proReadUnit => 'قراءة';

  @override
  String get proKhatmahUnit => 'ختمات';

  @override
  String proSeconds(int seconds) {
    return '$seconds ثانية';
  }

  @override
  String proMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String proHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String get qiblaPermWarning => 'الرجاء تفعيل صلاحية الموقع من الإعدادات';

  @override
  String get qiblaFallbackWarning =>
      'تعذّر تحديد موقعك، عرض الاتجاه من مدينة الرياض';

  @override
  String get qiblaTimeoutTitle => 'توفير الطاقة';

  @override
  String get qiblaTimeoutBody => 'هل تريد متابعة تحديد القبلة؟';

  @override
  String get qiblaClose => 'إغلاق';

  @override
  String get qiblaContinue => 'متابعة';

  @override
  String get qiblaLockedSnack => '🔒 تم تثبيت اتجاه القبلة';

  @override
  String get qiblaUnlockedSnack => 'تم إلغاء التثبيت';

  @override
  String get qiblaCalibTitle => 'معايرة البوصلة';

  @override
  String get qiblaCalibHint => 'لتحسين دقة البوصلة:';

  @override
  String get qiblaCalib1 => '1. أبعد الهاتف عن أي معادن';

  @override
  String get qiblaCalib2 => '2. حرّك الهاتف بشكل 8';

  @override
  String get qiblaCalib3 => '3. كرر حتى تتحسن الدقة';

  @override
  String get qiblaTitle => 'اتجاه القبلة';

  @override
  String get qiblaLocating => 'جارٍ تحديد موقعك...';

  @override
  String get qiblaLockedBadge => '🔒 اتجاه مثبت';

  @override
  String get qiblaPinned => '🔒 تم التثبيت';

  @override
  String get qiblaCalibNeeded => 'معايرة مطلوبة';

  @override
  String get qiblaKaaba => '🕋 الكعبة';

  @override
  String get qiblaDirection => 'اتجاه القبلة';

  @override
  String get qiblaDistance => 'المسافة';

  @override
  String get qiblaBearing => 'الاتجاه';

  @override
  String get qiblaLock => 'تثبيت';

  @override
  String get qiblaUnlock => 'إلغاء';

  @override
  String get obSkip => 'تخطي';

  @override
  String get obNext => 'التالي';

  @override
  String get obStart => 'ابدأ الآن';

  @override
  String get ob1Title => 'أهلاً بك في نور';

  @override
  String get ob1Subtitle => 'بيئة عبادة رقمية شاملة';

  @override
  String get ob1Desc =>
      'تلاوة القرآن، حفظ الأحاديث، مواقيت الصلاة، والأذكار في مكان واحد';

  @override
  String get ob2Title => 'القرآن الكريم';

  @override
  String get ob2Subtitle => 'تلاوة وتدبر';

  @override
  String get ob2Desc => 'قراءة بالخط العثماني، تفسير، وأصوات لعدة قراء';

  @override
  String get ob3Title => 'الأحاديث النبوية';

  @override
  String get ob3Subtitle => 'الكتب التسعة';

  @override
  String get ob3Desc =>
      'بحث متقدم، شجرة موضوعية، تخريج، وحفظ بالتكرار المتباعد';

  @override
  String get ob4Title => 'مواقيت الصلاة';

  @override
  String get ob4Subtitle => 'دقيقة وذكية';

  @override
  String get ob4Desc => 'تنبيهات الصلاة، وضع صامت تلقائي، واتجاه القبلة';

  @override
  String get ob5Title => 'هل أنت مستعد؟';

  @override
  String get ob5Subtitle => 'ابدأ رحلتك الروحية';

  @override
  String get ob5Desc =>
      'نسأل الله أن يجعل هذا التطبيق نافعاً لك في دينك ودنياك';

  @override
  String get npcBadge => 'الصلاة القادمة';

  @override
  String get npcLoading => 'جاري التحميل...';

  @override
  String npcAfter(String remaining) {
    return 'بعد $remaining';
  }

  @override
  String get npcInshallah => 'إن شاء الله';

  @override
  String get alibTitle => 'مكتبة الأذكار';

  @override
  String get alibReviewBanner => 'محتوى المكتبة قيد المراجعة العلمية';

  @override
  String alibCount(int count) {
    return '$count ذكر';
  }

  @override
  String alibSource(String ref) {
    return 'المصدر: $ref';
  }

  @override
  String get favAdhkar => 'الأذكار';

  @override
  String get continueStart => 'ابدأ القراءة';

  @override
  String get continueSaved => 'محفوظ';

  @override
  String continueAyah(int ayah) {
    return 'الآية $ayah';
  }

  @override
  String get continueGo => 'اضغط للانتقال إلى المصحف';

  @override
  String dayTasks(int done) {
    return '$done/5 صلوات';
  }

  @override
  String dayStreak(int streak) {
    return '🔥 $streak يوم متتالي';
  }

  @override
  String get adhkarCardDone => 'أتممت الورد اليومي';

  @override
  String get adhkarCardTodo => 'واصل ذكر الله';

  @override
  String adhkarCardPct(int pct) {
    return '$pct% مكتمل';
  }

  @override
  String get sugTipTitle => '💡 اقتراح ذكي الآن:';

  @override
  String get tfwPreviewText => 'معاينة النص';

  @override
  String get npcTomorrow => 'غداً';

  @override
  String get a11yPrevious => 'السابق';

  @override
  String get a11yNext => 'التالي';

  @override
  String a11yTasbihCount(int count) {
    return 'العدد: $count';
  }
}

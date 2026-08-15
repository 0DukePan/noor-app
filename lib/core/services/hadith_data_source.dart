import '../data/data_sources/hadith_database.dart';

/// مصدر بيانات الأحاديث — مدعوم بالكامل من قاعدة SQLite (نفس البيانات التي
/// يستخدمها القارئ والبحث). لم تعد ملفات JSON تُقرأ في وقت التشغيل؛ تُبنى
/// قاعدة البيانات مسبقاً (tool/build_hadith_db.dart) وتُنسخ عند أول تشغيل.
class HadithDataSource {
  // The 9 Major Books of Hadith
  static const Map<String, HadithBookInfo> majorBooks = {
    'bukhari': HadithBookInfo(
      id: 'bukhari',
      arabicName: 'صحيح البخاري',
      englishName: 'Sahih al-Bukhari',
      author: 'الإمام محمد بن إسماعيل البخاري',
      hadithCount: 7277,
    ),
    'muslim': HadithBookInfo(
      id: 'muslim',
      arabicName: 'صحيح مسلم',
      englishName: 'Sahih Muslim',
      author: 'الإمام مسلم بن الحجاج',
      hadithCount: 7563,
    ),
    'abudawud': HadithBookInfo(
      id: 'abudawud',
      arabicName: 'سنن أبي داود',
      englishName: 'Sunan Abu Dawud',
      author: 'الإمام أبو داود السجستاني',
      hadithCount: 5274,
    ),
    'tirmidhi': HadithBookInfo(
      id: 'tirmidhi',
      arabicName: 'جامع الترمذي',
      englishName: 'Jami at-Tirmidhi',
      author: 'الإمام أبو عيسى الترمذي',
      hadithCount: 3956,
    ),
    'nasai': HadithBookInfo(
      id: 'nasai',
      arabicName: 'سنن النسائي',
      englishName: "Sunan an-Nasa'i",
      author: 'الإمام أحمد بن شعيب النسائي',
      hadithCount: 5662,
    ),
    'ibnmajah': HadithBookInfo(
      id: 'ibnmajah',
      arabicName: 'سنن ابن ماجه',
      englishName: 'Sunan Ibn Majah',
      author: 'الإمام محمد بن يزيد ابن ماجه',
      hadithCount: 4341,
    ),
    'malik': HadithBookInfo(
      id: 'malik',
      arabicName: 'موطأ مالك',
      englishName: 'Muwatta Malik',
      author: 'الإمام مالك بن أنس',
      hadithCount: 1594,
    ),
    'ahmed': HadithBookInfo(
      id: 'ahmed',
      arabicName: 'مسند أحمد',
      englishName: 'Musnad Ahmad',
      author: 'الإمام أحمد بن حنبل',
      hadithCount: 26363,
    ),
    'darimi': HadithBookInfo(
      id: 'darimi',
      arabicName: 'سنن الدارمي',
      englishName: 'Sunan ad-Darimi',
      author: 'الإمام عبد الله بن عبد الرحمن الدارمي',
      hadithCount: 3364,
    ),
  };

  static Future<void> init() async {
    // All hadith content comes from the SQLite database — no Hive cache.
  }

  /// حديث عشوائي (لحديث اليوم) — مباشرة من قاعدة SQLite.
  static Future<Map<String, dynamic>?> getRandomHadith({String? bookId}) async {
    final row = bookId == null
        ? await HadithDatabase.getRandomHadith()
        : await HadithDatabase.getRandomHadithFromBook(bookId);
    if (row == null) return null;
    final collection = row['collection_id'] as String? ?? bookId ?? '';
    return {
      ...Map<String, dynamic>.from(row),
      'bookId': collection,
      'bookName': majorBooks[collection]?.arabicName ?? collection,
    };
  }

  /// حديث اليوم (ثابت طوال اليوم) — من قاعدة SQLite.
  static Future<Map<String, dynamic>?> getDailyHadith() async {
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year)).inDays;
    final row = await HadithDatabase.getDailyHadith(dayOfYear);
    if (row == null) return null;
    final collection = row['collection_id'] as String? ?? 'bukhari';
    return {
      ...Map<String, dynamic>.from(row),
      'bookId': collection,
      'bookName': majorBooks[collection]?.arabicName ?? collection,
    };
  }

  /// بيانات الكتب التسعة
  static List<HadithBookInfo> getBooks() => majorBooks.values.toList();
}

/// معلومات كتاب
class HadithBookInfo {

  const HadithBookInfo({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.author,
    required this.hadithCount,
  });
  final String id;
  final String arabicName;
  final String englishName;
  final String author;
  final int hadithCount;
}

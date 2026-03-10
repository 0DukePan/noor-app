import '../../domain/entities/hadith.dart';
import '../../domain/repositories/hadith_repository.dart';
import '../data_sources/local_hadith_data_source.dart';

class HadithRepositoryImpl implements HadithRepository {
  final LocalHadithDataSource _dataSource;

  HadithRepositoryImpl(this._dataSource);

  @override
  Future<List<HadithCollection>> getCollections() async {
    // These are static metadata for the 9 books and 40 Nawawi
    // In a real app, this might come from `assets/hadith/collections.json`
    // For now, we hardcode the 9 books as per `assets` exploration.
    
    return [
      const HadithCollection(
        id: 'bukhari',
        titleArabic: 'صحيح البخاري',
        titleEnglish: 'Sahih al-Bukhari',
        hadithsCount: 7563,
        author: 'Imam Bukhari',
      ),
      const HadithCollection(
        id: 'muslim',
        titleArabic: 'صحيح مسلم',
        titleEnglish: 'Sahih Muslim',
        hadithsCount: 3033,
        author: 'Imam Muslim',
      ),
      const HadithCollection(
        id: 'abudawud',
        titleArabic: 'سنن أبي داود',
        titleEnglish: 'Sunan Abu Dawud',
        hadithsCount: 5274,
        author: 'Abu Dawud',
      ),
       const HadithCollection(
        id: 'tirmidhi',
        titleArabic: 'جامع الترمذي',
        titleEnglish: 'Jami at-Tirmidhi',
        hadithsCount: 3956,
        author: 'At-Tirmidhi',
      ),
      const HadithCollection(
        id: 'nasai',
        titleArabic: 'سنن النسائي',
        titleEnglish: 'Sunan an-Nasa\'i',
        hadithsCount: 5758,
        author: 'An-Nasa\'i',
      ),
      const HadithCollection(
        id: 'ibnmajah',
        titleArabic: 'سنن ابن ماجه',
        titleEnglish: 'Sunan Ibn Majah',
        hadithsCount: 4341,
        author: 'Ibn Majah',
      ),
       const HadithCollection(
        id: 'malik',
        titleArabic: 'موطأ مالك',
        titleEnglish: 'Muwatta Malik',
        hadithsCount: 1858,
        author: 'Imam Malik',
      ),
      const HadithCollection(
        id: 'ahmed',
        titleArabic: 'مسند أحمد',
        titleEnglish: 'Musnad Ahmad',
        hadithsCount: 26363,
        author: 'Imam Ahmad',
      ),
      const HadithCollection(
        id: 'darimi',
        titleArabic: 'سنن الدارمي',
        titleEnglish: 'Sunan Ad-Darimi',
        hadithsCount: 3367,
        author: 'Ad-Darimi',
      ),
      const HadithCollection(
        id: 'nawawi40',
        titleArabic: 'الأربعون النووية',
        titleEnglish: '40 Hadith Nawawi',
        hadithsCount: 42,
        author: 'Imam Nawawi',
      ),
    ];
  }

  @override
  Future<HadithBook> getBook(String bookId) async {
    // Handle the special case for 40 Nawawi if ID structure differs
    // My LocalHadithDataSource expects ID to match filename in `the_9_books`
    // I need to adjust DataSource or ID here.
    // Let's assume ID passed here is just the filename base.
    
    // Logic: if bookId contains /, it's a subpath.
    // But `LocalHadithDataSource` currently hardcodes `assets/hadith/by_book/the_9_books/$bookId.json`
    // I should update DataSource to be flexible or handle it here.
    // Updating DataSource is cleaner. But for now, let's stick to the 9 books.
    
    if (bookId.contains('nawawi')) {
       // TODO: Update DataSource to support diverse paths
       // For this phase, let's focus on the 9 books which are the heavy ones.
       // We will pass 'nawawi40' but DataSource needs upgrade.
    }
    
    return _dataSource.loadBook(bookId);
  }

  @override
  Future<List<Hadith>> getHadiths(String bookId, {required int page, required int limit}) async {
    // Ensure book is loaded (Repository coordinates this)
    // Ideally getBook updates the cache.
    // We assume getBook was called or we call it lightly.
    // _dataSource.loadBook checks cache first.
    await _dataSource.loadBook(bookId); // Implementation detail: ensures cache is hot
    
    return _dataSource.getHadithsPage(bookId: bookId, page: page, limit: limit);
  }

  @override
  Future<List<Hadith>> searchHadiths(String query, String bookId) async {
    await _dataSource.loadBook(bookId);
    return _dataSource.searchInBook(bookId, query);
  }

  @override
  Future<List<HadithChapter>> getChapters(String bookId) async {
    final book = await _dataSource.loadBook(bookId);
    return book.chapters;
  }
}

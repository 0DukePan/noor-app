/// Arabic display names for hadith collection IDs.
///
/// The canonical IDs come from `core/data/data_sources/hadith_database.dart`.
/// `ahmad` is kept as an alias for `ahmed` because some call sites use it.
const Map<String, String> kHadithBookNames = {
  'bukhari': 'صحيح البخاري',
  'muslim': 'صحيح مسلم',
  'abudawud': 'سنن أبي داود',
  'tirmidhi': 'جامع الترمذي',
  'nasai': 'سنن النسائي',
  'ibnmajah': 'سنن ابن ماجه',
  'malik': 'موطأ مالك',
  'ahmed': 'مسند أحمد',
  'ahmad': 'مسند أحمد',
  'darimi': 'سنن الدارمي',
  'nawawi40': 'الأربعون النووية',
  'qudsi40': 'الأحاديث القدسية',
  'shahwaliullah40': 'الأربعون للشاه ولي الله الدهلوي',
  'riyad_assalihin': 'رياض الصالحين',
  'bulugh_almaram': 'بلوغ المرام',
  'aladab_almufrad': 'الأدب المفرد',
  'mishkat_almasabih': 'مشكاة المصابيح',
  'shamail_muhammadiyah': 'الشمائل المحمدية',
};

/// Returns the Arabic name for a collection id, falling back to the id itself.
String hadithBookName(String id) => kHadithBookNames[id] ?? id;

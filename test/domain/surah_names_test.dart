import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/domain/entities/surah_names.dart';

/// Tests for the 114 surah names table and the 1-based lookup helper.
void main() {
  test('the table holds all 114 surah names', () {
    expect(kSurahNames.length, 114);
    expect(kSurahNames.toSet().length, 114, reason: 'names must be unique');
  });

  test('lookup is 1-based and returns the correct name', () {
    expect(surahName(1), 'الفاتحة');
    expect(surahName(2), 'البقرة');
    expect(surahName(114), 'الناس');
  });

  test('out-of-range surah numbers fall back to a generic label', () {
    expect(surahName(0), 'القرآن الكريم');
    expect(surahName(-3), 'القرآن الكريم');
    expect(surahName(115), 'القرآن الكريم');
    expect(surahName(1000), 'القرآن الكريم');
  });
}

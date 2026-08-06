import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/isnad_parser_service.dart';

void main() {
  group('IsnadParserService.parseChain', () {
    test('extracts the chain and stops at the Companion (no matn leakage)', () {
      final chain = IsnadParserService.parseChain(
        'حَدَّثَنَا مُحَمَّدُ بْنُ إِسْمَاعِيلَ، حَدَّثَنَا عَبْدُ اللَّهِ بْنُ يُوسُفَ، '
        'أَخْبَرَنَا مَالِكٌ، عَنْ نَافِعٍ، عَنْ عَبْدِ اللَّهِ بْنِ عُمَرَ رَضِيَ '
        'اللَّهُ عَنْهُمَا، أَنَّ رَسُولَ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ '
        'قَالَ: لَا يَقْبَلُ اللَّهُ صَلَاةً بِغَيْرِ طُهُورٍ',
      );

      expect(chain.length, greaterThanOrEqualTo(4));
      // Matn words must never appear as narrators.
      for (final n in chain) {
        expect(n.normalizedName, isNot(contains('يقبل')));
        expect(n.normalizedName, isNot(contains('طهور')));
        expect(n.normalizedName, isNot(contains('صلاة')));
      }
      // The last extracted narrator is the Companion.
      expect(chain.last.isCompanion, isTrue);
    });

    test('a narrator named Muhammad is NOT classified as the Prophet', () {
      final chain = IsnadParserService.parseChain(
        'حَدَّثَنَا مُحَمَّدُ بْنُ إِسْمَاعِيلَ، حَدَّثَنَا عَبْدُ اللَّهِ بْنُ يُوسُفَ، '
        'عَنْ مَالِكٍ، عَنْ نَافِعٍ، عَنِ النَّبِيِّ ﷺ',
      );

      expect(chain.isNotEmpty, isTrue);
      final first = chain.first;
      expect(first.normalizedName, contains('محمد'));
      expect(first.isProphet, isFalse);
      // The chain should end at the Prophet.
      expect(chain.last.isProphet, isTrue);
    });

    test('detects the Prophet via رسول الله', () {
      final chain = IsnadParserService.parseChain(
        'حَدَّثَنَا مُحَمَّدُ، حَدَّثَنَا سُفْيَانُ، عَنِ الزُّهْرِيِّ، '
        'عَنْ أَبِي هُرَيْرَةَ، عَنْ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ قَالَ: '
        'مَنْ نَفَّسَ عَنْ مُؤْمِنٍ كُرْبَةً فَرَّجَ اللَّهُ عَنْهُ كُرْبَةً',
      );

      expect(chain.isNotEmpty, isTrue);
      expect(chain.last.isProphet, isTrue);
    });

    test('restores the diacritized original narrator name', () {
      final chain = IsnadParserService.parseChain(
        'حَدَّثَنَا مُحَمَّدُ بْنُ الْمُثَنَّى، حَدَّثَنَا عَبْدُ الْوَهَّابِ، عَنْ أَيُّوبَ، '
        'عَنْ أَبِي هُرَيْرَةَ رَضِيَ اللَّهُ عَنْهُ، قَالَ رَسُولُ اللَّهِ ﷺ',
      );

      expect(chain.isNotEmpty, isTrue);
      expect(chain.first.name, contains('مُحَمَّدُ'));
    });

    test('the short keyword نا inside a word like منا is not a keyword', () {
      // "منا" appears mid-sentence. The old parser would treat the trailing
      // "نا" as a transmission keyword and fabricate a narrator.
      final chain = IsnadParserService.parseChain(
        'حَدَّثَنَا مُحَمَّدٌ مِنَّا خَيْرُ النَّاسِ',
      );

      // Only the opening haddathana should produce (at most) one narrator.
      expect(chain.length, lessThanOrEqualTo(1));
    });

    test('empty and non-arabic inputs are handled gracefully', () {
      expect(IsnadParserService.parseChain(''), isEmpty);
      expect(IsnadParserService.parseChain('The quick brown fox'), isEmpty);
    });
  });
}

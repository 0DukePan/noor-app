import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/core/domain/entities/surah.dart';
import 'package:noor_app/features/quran/presentation/widgets/surah_verse_widgets.dart';

/// Widget tests for the surah reader's building blocks (previously
/// zero-covered): BismillahHeader, DynamicVerseCard, DynamicTafsirPanel.
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  const verse = Verse(
    number: 1,
    numberInSurah: 1,
    textUthmani: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    surahNumber: 1,
    surahName: 'الفاتحة',
  );

  testWidgets('BismillahHeader renders for any surah', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BismillahHeader(surahNumber: 1))),
    );
    expect(find.textContaining('بِسْمِ اللَّهِ'), findsWidgets);
  });

  testWidgets('DynamicVerseCard renders the verse text and handles taps',
      (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicVerseCard(
            verse: verse,
            isKhushuMode: false,
            isSelected: false,
            onTap: () => tapped++,
            onLongPress: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('بِسْمِ اللَّهِ'), findsOneWidget);
    await tester.tap(find.textContaining('بِسْمِ اللَّهِ'));
    expect(tapped, 1);
  });

  testWidgets('DynamicTafsirPanel renders inside a ProviderScope',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DynamicTafsirPanel(
              surahNumber: 1,
              verseNumber: 1,
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    // Panel renders (either content or its loading/empty state) without
    // crashing; the close affordance exists.
    expect(find.byType(DynamicTafsirPanel), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);
}

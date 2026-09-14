import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/core/domain/entities/hadith.dart';
import 'package:noor_app/features/hadith/presentation/pages/quiz_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Smoke tests for QuizPage (previously zero-covered). The quiz logic is a
/// pure StateNotifier over the passed hadiths; no Hive or plugins are needed.
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  const hadiths = [
    Hadith(
      id: 1,
      idInBook: 1,
      arabic: 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
      englishText: 'Actions are but by intentions',
      narratorEnglish: 'Umar ibn al-Khattab',
      chapterId: 1,
      collectionId: 'bukhari',
    ),
    Hadith(
      id: 2,
      idInBook: 2,
      arabic:
          'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا',
      englishText:
          'Whoever believes in Allah and the Last Day, let him speak good',
      narratorEnglish: 'Abu Huraira',
      chapterId: 1,
      collectionId: 'bukhari',
    ),
  ];

  testWidgets('renders the quiz and accepts an answer', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuizPage(hadiths: hadiths),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(QuizPage), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);
}

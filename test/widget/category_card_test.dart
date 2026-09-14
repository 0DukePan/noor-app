import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/core/widgets/category_card.dart';

/// Widget tests for CategoryCard: title/subtitle/icon/emoji variants render
/// and taps reach the callback.
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpCard(WidgetTester tester, CategoryCard card) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SizedBox(width: 200, height: 200, child: card))),
    );
  }

  testWidgets('renders title and fires onTap', (tester) async {
    var tapped = false;
    await pumpCard(
      tester,
      CategoryCard(
        title: 'القرآن الكريم',
        color: Colors.green,
        onTap: () => tapped = true,
      ),
    );
    expect(find.text('القرآن الكريم'), findsOneWidget);
    await tester.tap(find.byType(CategoryCard));
    expect(tapped, isTrue);
  });

  testWidgets('renders subtitle and emoji variant', (tester) async {
    await pumpCard(
      tester,
      CategoryCard(
        title: 'الحديث',
        subtitle: 'صحيح البخاري',
        emoji: '📚',
        color: Colors.brown,
        onTap: () {},
      ),
    );
    expect(find.text('الحديث'), findsOneWidget);
    expect(find.text('صحيح البخاري'), findsOneWidget);
    expect(find.text('📚'), findsOneWidget);
    // No subtitle-free overflow: the subtitle branch renders exactly once.
    expect(find.byType(InkWell), findsOneWidget);
  });

  testWidgets('renders icon variant and selected state without crashing',
      (tester) async {
    await pumpCard(
      tester,
      CategoryCard(
        title: 'القبلة',
        icon: Icons.explore,
        color: Colors.teal,
        isSelected: true,
        onTap: () {},
      ),
    );
    expect(find.byIcon(Icons.explore), findsOneWidget);
  });
}

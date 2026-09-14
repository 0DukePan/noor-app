import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/shared/widgets/loading_skeleton.dart';

/// Widget tests for the loading skeletons: every constructor variant and
/// every list skeleton renders without crashing.
void main() {
  Future<void> pumpSkeleton(WidgetTester tester, Widget skeleton) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: skeleton)));
  }

  testWidgets('default skeleton renders with default dimensions',
      (tester) async {
    await pumpSkeleton(tester, const LoadingSkeleton());
    expect(find.byType(LoadingSkeleton), findsOneWidget);
    // The shimmer body is a decorated container.
    expect(find.byType(Container), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('named constructors render circle, text and card variants',
      (tester) async {
    await pumpSkeleton(
      tester,
      const Column(
        children: [
          LoadingSkeleton.text(width: 120),
          LoadingSkeleton.circle(size: 40),
          LoadingSkeleton.card(height: 150),
        ],
      ),
    );
    expect(find.byType(LoadingSkeleton), findsNWidgets(3));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('SurahListSkeleton renders the requested item count',
      (tester) async {
    await pumpSkeleton(tester, const SurahListSkeleton(itemCount: 3));
    expect(find.byType(ListView), findsOneWidget);
    // Each item holds one circle avatar plus two text lines.
    expect(find.byType(LoadingSkeleton), findsNWidgets(3 * 3));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('HadithListSkeleton renders', (tester) async {
    await pumpSkeleton(tester, const HadithListSkeleton(itemCount: 2));
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(LoadingSkeleton), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('VerseListSkeleton renders', (tester) async {
    await pumpSkeleton(tester, const VerseListSkeleton(itemCount: 2));
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(LoadingSkeleton), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('PrayerTimesSkeleton renders card plus five rows',
      (tester) async {
    await pumpSkeleton(
      tester,
      const SingleChildScrollView(child: PrayerTimesSkeleton()),
    );
    expect(find.byType(PrayerTimesSkeleton), findsOneWidget);
    expect(find.byType(LoadingSkeleton), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });
}

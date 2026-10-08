import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/models/tafsir_models.dart';
import 'package:noor_app/core/widgets/tafsir_state_view.dart';

/// TAF-02 contract: every Tafsir surface renders loading, content, truthful
/// empty, and failure-with-retry through this one switch. Variants differ
/// only in content/strings/styling — never in state behavior.
void main() {
  const entry = TafsirEntry(
    surah: 1,
    ayah: 1,
    text: 'نص التفسير',
    source: TafsirSourceId.muyassar,
  );

  Future<void> pumpState(
    WidgetTester tester,
    TafsirViewState state, {
    bool retried = false,
    VoidCallback? onRetry,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TafsirStateView(
            state: state,
            contentBuilder: (e) => Text('content:${e.text}'),
            onRetry: onRetry ?? () {},
            emptyText: 'empty-state',
            failureText: 'failure-state',
            retryText: 'retry-state',
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('loading renders exactly one spinner', (tester) async {
    await pumpState(tester, const TafsirViewLoading());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('content:نص التفسير'), findsNothing);
  });

  testWidgets('content renders the builder output', (tester) async {
    await pumpState(tester, const TafsirViewContent(entry));
    expect(find.text('content:نص التفسير'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('empty tells the truth without a retry', (tester) async {
    await pumpState(
      tester,
      const TafsirViewEmpty(TafsirAvailability.rowMissing),
    );
    expect(find.text('empty-state'), findsOneWidget);
    expect(find.text('retry-state'), findsNothing);
    expect(find.text('failure-state'), findsNothing);
  });

  testWidgets('failure shows retry and invokes it once', (tester) async {
    var retries = 0;
    await pumpState(
      tester,
      const TafsirViewFailure(TafsirAvailability.storageFailure),
      onRetry: () => retries++,
    );
    expect(find.text('failure-state'), findsOneWidget);
    await tester.tap(find.text('retry-state'));
    await tester.pump();
    expect(retries, 1);
  });

  test('tafsirViewStateFor maps every availability truthfully', () {
    expect(
      tafsirViewStateFor(
        entry: entry,
        availability: TafsirAvailability.available,
      ),
      isA<TafsirViewContent>(),
    );
    expect(
      tafsirViewStateFor(
        entry: null,
        availability: TafsirAvailability.rowMissing,
      ),
      isA<TafsirViewEmpty>(),
    );
    expect(
      tafsirViewStateFor(
        entry: null,
        availability: TafsirAvailability.sourceDisabled,
      ),
      isA<TafsirViewEmpty>(),
    );
    expect(
      tafsirViewStateFor(
        entry: null,
        availability: TafsirAvailability.storageFailure,
      ),
      isA<TafsirViewFailure>(),
    );
    expect(
      tafsirViewStateFor(entry: null, availability: TafsirAvailability.corrupt),
      isA<TafsirViewFailure>(),
    );
    // Defensive: available status without an entry degrades to empty.
    expect(
      tafsirViewStateFor(
        entry: null,
        availability: TafsirAvailability.available,
      ),
      isA<TafsirViewEmpty>(),
    );
  });
}

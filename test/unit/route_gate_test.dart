import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/router/app_router.dart';

/// Router gate contract (QUR-04): a fresh boot into a deep link parks on
/// onboarding WITHOUT losing the target; plain boots stash nothing, so
/// normal onboarding still lands on home. The end-to-end wiring (redirect +
/// onboarding completion) is covered by tests/quran-flow.e2e.ts.
void main() {
  // Each case starts with an empty stash.
  setUp(consumePendingDeepLink);

  test('unseen deep link parks on onboarding and stashes the target', () {
    final redirect = onboardingGateRedirect(
      onboardingSeen: false,
      uri: Uri.parse('/quran/mushaf?page=2'),
    );
    expect(redirect, '/onboarding');
    expect(consumePendingDeepLink(), '/quran/mushaf?page=2');
    // Single-shot: consumed exactly once.
    expect(consumePendingDeepLink(), isNull);
  });

  test('plain boot stashes nothing', () {
    expect(
      onboardingGateRedirect(onboardingSeen: false, uri: Uri.parse('/')),
      '/onboarding',
    );
    expect(consumePendingDeepLink(), isNull);
  });

  test('seen users and the onboarding route itself pass through', () {    expect(
      onboardingGateRedirect(
        onboardingSeen: true,
        uri: Uri.parse('/quran/mushaf?page=2'),
      ),
      isNull,
    );
    expect(
      onboardingGateRedirect(
        onboardingSeen: false,
        uri: Uri.parse('/onboarding'),
      ),
      isNull,
    );
    expect(consumePendingDeepLink(), isNull);
  });

  test('stashInitialDeepLink keeps full path+query, skips roots', () {
    stashInitialDeepLink(Uri.parse('http://x/quran/mushaf?page=2'));
    expect(consumePendingDeepLink(), '/quran/mushaf?page=2');

    stashInitialDeepLink(Uri.parse('http://x/'));
    expect(consumePendingDeepLink(), isNull);

    stashInitialDeepLink(Uri.parse('http://x/onboarding'));
    expect(consumePendingDeepLink(), isNull);
  });
}

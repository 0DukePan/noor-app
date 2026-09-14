import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/domain/policies/policies.dart';
import 'package:noor_app/core/services/services.dart';

/// Barrel-import test: verifies the two barrel files resolve and re-export
/// their members. Importing a barrel executes its (empty) library body, which
/// is the only honest coverage a pure `export` file can get.
void main() {
  test('services barrel re-exports engine and service symbols', () {
    // A symbol from the prayer engine and one from the seasonal offsets
    // engine — both must be visible through services.dart.
    expect(PrayerTimeEngine, isNotNull);
    expect(SeasonalOffsetsEngine, isNotNull);
  });

  test('policies barrel re-exports the policy interfaces', () {
    expect(PrivacyPolicy, isNotNull);
    expect(OfflinePolicy, isNotNull);
    expect(KhushuPolicy, isNotNull);
  });
}

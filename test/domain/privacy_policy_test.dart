import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/domain/policies/privacy_policy.dart';

/// Privacy policy (previously only barrel-imported): AES round-trip, random
/// IVs, corrupt-input safety, and the local-only sync/track denials.
/// Pure Dart throughout.
void main() {
  DefaultPrivacyPolicy policy() =>
      DefaultPrivacyPolicy(encryptionKey: 'test-key-123');

  test('encrypt/decrypt round-trips Arabic text', () {
    const plain = 'تأمل في الآية الأولى من الفاتحة';
    final cipher = policy().encryptLocalData(plain);
    expect(cipher, isNotEmpty);
    expect(cipher, isNot(contains(plain)));
    expect(policy().decryptLocalData(cipher), plain);
  });

  test('empty plaintext stays empty through both directions', () {
    expect(policy().encryptLocalData(''), '');
    expect(policy().decryptLocalData(''), '');
  });

  test('random IVs make identical plaintexts differ', () {
    const plain = 'same text';
    final first = policy().encryptLocalData(plain);
    final second = policy().encryptLocalData(plain);
    expect(first, isNot(equals(second)));
    expect(policy().decryptLocalData(first), plain);
    expect(policy().decryptLocalData(second), plain);
  });

  test('corrupt ciphertext fails closed without throwing', () {
    expect(policy().decryptLocalData('no-separator-here'), '');
    expect(policy().decryptLocalData(':::too:many'), '');
    expect(policy().decryptLocalData('!!!:!!!'), '');
  });

  test('local-only build denies all sync and all tracking', () {
    final instance = policy();
    for (final category in DataCategory.values) {
      expect(
        instance.canSyncToCloud(category),
        isFalse,
        reason: 'must stay false until a reviewed backend ships',
      );
    }
    expect(instance.canTrackUser(), isFalse);
    expect(DataCategory.values, hasLength(6));
  });
}

import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// يوفّر مفتاح تشفير مشتق من الجهاز - Device-derived encryption keys
///
/// Generates a random 32-byte key on first use and stores it in the platform
/// secure storage (Keychain/Keystore/DPAPI). The key is never hardcoded and
/// never leaves the device.
class SecureKeyService {
  SecureKeyService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Returns the 32-byte (base64) encryption key for the given namespace,
  /// generating and persisting a new random key when none exists yet.
  static Future<String> getOrCreateKey(String namespace) async {
    const keyName = 'noor_encryption_key';
    final stored = await _storage.read(key: '$keyName:$namespace');
    if (stored != null && stored.isNotEmpty) return stored;

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final key = base64Encode(bytes);
    await _storage.write(key: '$keyName:$namespace', value: key);
    return key;
  }
}

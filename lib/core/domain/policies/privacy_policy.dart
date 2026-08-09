import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

/// سياسة الخصوصية - Privacy Policy
/// Enforces local encryption and data protection at the code level.
/// All personal data (reflections, notes) MUST be encrypted locally.
abstract class PrivacyPolicy {
  /// Encrypt data before storing locally
  String encryptLocalData(String plainText);

  /// Decrypt data when reading from local storage
  String decryptLocalData(String encryptedText);

  /// Whether data can be synced to cloud
  /// Personal reflections should NEVER sync without explicit consent
  bool canSyncToCloud(DataCategory category);

  /// Whether analytics/tracking is allowed
  /// Always returns false - we track crashes, not people
  bool canTrackUser() => false;
}

/// Categories of data for privacy decisions
enum DataCategory {
  /// Personal reflections on Quran verses
  tadabbur,

  /// User's Quran reading progress
  readingProgress,

  /// Adhkar completion counts
  adhkarProgress,

  /// Prayer qada records
  qadaRecords,

  /// App settings and preferences
  settings,

  /// Bookmarks and favorites
  bookmarks,
}

/// Default implementation of Privacy Policy
class DefaultPrivacyPolicy implements PrivacyPolicy {
  final Key _encryptionKey;
  late final Encrypter _encrypter;

  DefaultPrivacyPolicy({required String encryptionKey})
      : _encryptionKey = Key.fromUtf8(encryptionKey.padRight(32).substring(0, 32)) {
    _encrypter = Encrypter(AES(_encryptionKey));
  }

  /// A random IV is generated for every encryption and prepended to the
  /// ciphertext, so the same plaintext never produces the same output.
  @override
  String encryptLocalData(String plainText) {
    if (plainText.isEmpty) return '';
    final ivBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final iv = IV(Uint8List.fromList(ivBytes));
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    return '${base64Encode(ivBytes)}:${encrypted.base64}';
  }

  @override
  String decryptLocalData(String encryptedText) {
    if (encryptedText.isEmpty) return '';
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return '';
      final iv = IV(base64Decode(parts[0]));
      final decrypted = _encrypter.decrypt64(parts[1], iv: iv);
      return decrypted;
    } catch (e) {
      // Return empty string if decryption fails (corrupted data)
      return '';
    }
  }

  @override
  bool canSyncToCloud(DataCategory category) {
    switch (category) {
      case DataCategory.tadabbur:
        // Personal reflections NEVER sync automatically
        return false;
      case DataCategory.qadaRecords:
        // Qada records are private worship data
        return false;
      case DataCategory.readingProgress:
        // Can sync if user opts in
        return true;
      case DataCategory.adhkarProgress:
        // Can sync for backup purposes
        return true;
      case DataCategory.settings:
        // Settings can sync for convenience
        return true;
      case DataCategory.bookmarks:
        // Bookmarks can sync
        return true;
    }
  }

  @override
  bool canTrackUser() => false; // We log crashes, not people
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Stores the Hive AES key in the platform secure enclave
/// (Android Keystore / iOS Secure Enclave) instead of a plain file.
class HiveEncryption {
  HiveEncryption._();

  static const _keyAlias = 'tunofy_hive_aes_key';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<HiveCipher?> get cipher async {
    try {
      final key = await _getOrCreateKey();
      return HiveAesCipher(Uint8List.fromList(key));
    } catch (e) {
      debugPrint('[HiveEncryption] Failed to build cipher: $e');
      return null;
    }
  }

  static Future<List<int>> _getOrCreateKey() async {
    final stored = await _storage.read(key: _keyAlias);
    if (stored != null) {
      return base64Decode(stored);
    }
    final key = Hive.generateSecureKey();
    await _storage.write(key: _keyAlias, value: base64Encode(key));
    return key;
  }
}

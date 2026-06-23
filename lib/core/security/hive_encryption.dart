import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class HiveEncryption {
  HiveEncryption._();

  static const String _keyFileName = '.tunofy_hive_key';

  static Future<HiveCipher?> get cipher async {
    try {
      final key = await _getOrCreateKey();
      return HiveAesCipher(Uint8List.fromList(key));
    } catch (_) {
      return null;
    }
  }

  static Future<List<int>> _getOrCreateKey() async {
    final dir = await getApplicationDocumentsDirectory();
    final keyFile = File('${dir.path}/$_keyFileName');

    if (await keyFile.exists()) {
      final encoded = await keyFile.readAsString();
      return base64Decode(encoded.trim());
    }

    final key = Hive.generateSecureKey();
    await keyFile.writeAsString(base64Encode(key));
    return key;
  }
}

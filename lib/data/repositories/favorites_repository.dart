import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

class FavoritesRepository {
  Box<String>? _favoritesBox;
  Box<String>? _recentBox;

  Future<void> init({HiveCipher? encryptionCipher}) async {
    _favoritesBox = await Hive.openBox<String>(
      AppConstants.favoritesBoxName,
      encryptionCipher: encryptionCipher,
    );
    _recentBox = await Hive.openBox<String>(
      AppConstants.recentlyPlayedBoxName,
      encryptionCipher: encryptionCipher,
    );
  }

  // ─── Favorites ─────────────────────────────────────────────────────────────

  bool isFavorite(String id) {
    return _favoritesBox?.containsKey(id) ?? false;
  }

  Future<void> addFavorite(String id, String type) async {
    await _favoritesBox?.put(id, type);
  }

  Future<void> removeFavorite(String id) async {
    await _favoritesBox?.delete(id);
  }

  Future<void> toggleFavorite(String id, String type) async {
    if (isFavorite(id)) {
      await removeFavorite(id);
    } else {
      await addFavorite(id, type);
    }
  }

  List<String> getFavoriteIds({String? type}) {
    final box = _favoritesBox;
    if (box == null) return [];
    if (type == null) return box.keys.cast<String>().toList();
    return box.keys
        .cast<String>()
        .where((k) => box.get(k) == type)
        .toList();
  }

  // ─── Recently Played ───────────────────────────────────────────────────────

  Future<void> addRecentlyPlayed(String id, String type) async {
    final box = _recentBox;
    if (box == null) return;
    // Remove if already exists (to re-insert at front)
    await box.delete(id);
    // Keep max 20 items
    if (box.length >= 20) {
      final firstKey = box.keys.first;
      await box.delete(firstKey);
    }
    await box.put(id, type);
  }

  List<String> getRecentIds({String? type}) {
    final box = _recentBox;
    if (box == null) return [];
    final keys = box.keys.cast<String>().toList().reversed.toList();
    if (type == null) return keys;
    return keys.where((k) => box.get(k) == type).toList();
  }

  Future<void> clearRecent({String? type}) async {
    final box = _recentBox;
    if (box == null) return;
    if (type == null) {
      await box.clear();
    } else {
      final keys = box.keys.cast<String>().toList();
      for (final k in keys) {
        if (box.get(k) == type) await box.delete(k);
      }
    }
  }
}

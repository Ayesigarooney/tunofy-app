import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

class SettingsRepository {
  Box? _settingsBox;

  Future<void> init({HiveCipher? encryptionCipher}) async {
    _settingsBox = await Hive.openBox(
      AppConstants.settingsBoxName,
      encryptionCipher: encryptionCipher,
    );
  }

  ThemeMode get themeMode {
    final value = _settingsBox?.get(AppConstants.themeModeKey, defaultValue: 'system') as String?;
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _settingsBox?.put(AppConstants.themeModeKey, value);
  }

  String? getChannelUrl(String channelId) {
    return _settingsBox?.get('channel_url_$channelId') as String?;
  }

  Future<void> setChannelUrl(String channelId, String url) async {
    await _settingsBox?.put('channel_url_$channelId', url);
  }

  String? getChannelRefreshPage(String channelId) {
    return _settingsBox?.get('channel_refresh_$channelId') as String?;
  }

  // ─── Offline cache ─────────────────────────────────────────────────────────

  String? getCachedRadioStationsJson() {
    return _settingsBox?.get('cached_radio_stations') as String?;
  }

  Future<void> setCachedRadioStationsJson(String json) async {
    await _settingsBox?.put('cached_radio_stations', json);
  }

  String? getCachedTvChannelsJson() {
    return _settingsBox?.get('cached_tv_channels') as String?;
  }

  Future<void> setCachedTvChannelsJson(String json) async {
    await _settingsBox?.put('cached_tv_channels', json);
  }
}

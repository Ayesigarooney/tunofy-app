import 'env_config.dart';

class AppConstants {
  AppConstants._();

  // API Keys - set via --dart-define at build time
  static const String tmdbApiKey = EnvConfig.tmdbApiKey;

  // TMDB API
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';

  // Hive Box Names
  static const String favoritesBoxName = 'favorites';
  static const String recentlyPlayedBoxName = 'recently_played';
  static const String settingsBoxName = 'settings';

  // Package name
  static const String packageName = 'com.tunofy.app';

  // Settings Keys
  static const String themeModeKey = 'theme_mode';

  // Stream retry config
  static const Duration retryDelay = Duration(seconds: 2);
}

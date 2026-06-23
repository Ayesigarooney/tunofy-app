import 'env_config.dart';

class AppConstants {
  AppConstants._();

  // API Keys - set via --dart-define at build time
  static const String tmdbApiKey = EnvConfig.tmdbApiKey;
  static const String youtubeApiKey = EnvConfig.youtubeApiKey;

  // TMDB API
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const String tmdbLargeImageBaseUrl = 'https://image.tmdb.org/t/p/original';

  // YouTube API
  static const String youtubeApiBaseUrl = 'https://www.googleapis.com/youtube/v3';

  // Hive Box Names
  static const String favoritesBoxName = 'favorites';
  static const String recentlyPlayedBoxName = 'recently_played';
  static const String settingsBoxName = 'settings';

  // Settings Keys
  static const String lowDataModeKey = 'low_data_mode';
  static const String themeModeKey = 'theme_mode';

  // Stream retry config
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration streamTimeout = Duration(seconds: 10);

  // Metadata polling interval
  static const Duration metadataPollingInterval = Duration(seconds: 5);
}

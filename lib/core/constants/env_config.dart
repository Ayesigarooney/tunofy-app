class EnvConfig {
  EnvConfig._();

  static const String tmdbApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: 'YOUR_TMDB_API_KEY',
  );

  static const String youtubeApiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: 'YOUR_YOUTUBE_API_KEY',
  );

  static bool get hasValidKeys =>
      tmdbApiKey != 'YOUR_TMDB_API_KEY' &&
      youtubeApiKey != 'YOUR_YOUTUBE_API_KEY';

  static bool get hasTmdbKey => tmdbApiKey != 'YOUR_TMDB_API_KEY';
  static bool get hasYoutubeKey => youtubeApiKey != 'YOUR_YOUTUBE_API_KEY';

  // Embedded playlist server port (0 = disabled)
  static const int serverPort = int.fromEnvironment(
    'SERVER_PORT',
    defaultValue: 0,
  );

  // Backend server URL (optional — if set, app fetches TV/radio from this server)
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );
}

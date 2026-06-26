class EnvConfig {
  EnvConfig._();

  static const String tmdbApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: 'YOUR_TMDB_API_KEY',
  );

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

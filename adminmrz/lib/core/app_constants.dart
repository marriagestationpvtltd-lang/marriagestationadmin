class AppConstants {
  static const String apiBaseUrl = 'https://digitallami.com/api9';
  static const String chatApiUrl = 'https://digitallami.com';

  static const Duration requestTimeout = Duration(seconds: 15);

  /// Default TTL for cached API responses.
  static const Duration cacheDuration = Duration(minutes: 5);

  /// Shorter TTL for dashboard / chat data that should feel "live".
  static const Duration liveCacheDuration = Duration(seconds: 30);

  /// How often the dashboard and chat list auto-refresh.
  static const Duration autoRefreshInterval = Duration(seconds: 30);
}

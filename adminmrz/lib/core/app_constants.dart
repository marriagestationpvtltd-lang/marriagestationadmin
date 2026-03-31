import 'package:flutter/foundation.dart';

class AppConstants {
  // On Flutter Web the app is served through Firebase Hosting, which rewrites
  // these paths to the `proxy` Cloud Function. The function forwards requests
  // to https://digitallami.com, adding the CORS headers that the browser
  // requires. On non-web platforms (Android / iOS) we call the server directly.
  static const String apiBaseUrl =
      kIsWeb ? '/api' : 'https://digitallami.com/api';
  static const String chatApiUrl =
      kIsWeb ? '' : 'https://digitallami.com';
  static const String api2BaseUrl =
      kIsWeb ? '/Api2' : 'https://digitallami.com/Api2';

  static const Duration requestTimeout = Duration(seconds: 15);

  /// Default TTL for cached API responses.
  static const Duration cacheDuration = Duration(minutes: 5);

  /// Shorter TTL for dashboard / chat data that should feel "live".
  static const Duration liveCacheDuration = Duration(seconds: 30);

  /// How often the dashboard and chat list auto-refresh.
  static const Duration autoRefreshInterval = Duration(seconds: 30);
}


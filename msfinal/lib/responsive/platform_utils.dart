import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'breakpoints.dart';

/// Platform and screen size utilities
class PlatformUtils {
  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile platform
  static bool get isMobile => !kIsWeb;

  /// Check if screen width is mobile size
  static bool isMobileWidth(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.mobile;
  }

  /// Check if screen width is tablet size
  static bool isTabletWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.desktop;
  }

  /// Check if screen width is desktop size
  static bool isDesktopWidth(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.desktop;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktopWidth(context)) {
      return desktop;
    } else if (isTabletWidth(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Private constructor
  PlatformUtils._();
}

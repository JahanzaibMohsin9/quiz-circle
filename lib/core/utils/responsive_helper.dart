import 'package:flutter/material.dart';

/// Responsive design helper for adaptive layouts
class ResponsiveHelper {
  ResponsiveHelper._();

  // Breakpoints (mobile-first approach)
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  /// Check if current device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    if (isDesktop(context)) return EdgeInsets.all(desktop);
    if (isTablet(context)) return EdgeInsets.all(tablet);
    return EdgeInsets.all(mobile);
  }

  /// Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(
    BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    if (isDesktop(context)) return EdgeInsets.symmetric(horizontal: desktop);
    if (isTablet(context)) return EdgeInsets.symmetric(horizontal: tablet);
    return EdgeInsets.symmetric(horizontal: mobile);
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Get responsive width with max constraint
  static double getResponsiveWidth(
    BuildContext context, {
    double mobilePercent = 1.0,
    double maxWidth = 600,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final calculatedWidth = screenWidth * mobilePercent;
    return calculatedWidth > maxWidth ? maxWidth : calculatedWidth;
  }

  /// Get number of grid columns based on screen size
  static int getGridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(
    BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}

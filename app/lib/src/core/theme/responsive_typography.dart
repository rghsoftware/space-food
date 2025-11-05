/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';

/// Responsive typography scales for different device types
class ResponsiveTypography {
  /// Mobile text theme (320-600px)
  static TextTheme mobileTextTheme(BuildContext context) {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
    );
  }

  /// Tablet text theme (600-1024px)
  static TextTheme tabletTextTheme(BuildContext context) {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
      bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  /// Desktop text theme (1024px+)
  static TextTheme desktopTextTheme(BuildContext context) {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    );
  }

  /// Kitchen display text theme (larger for viewing from distance)
  static TextTheme kitchenTextTheme(BuildContext context) {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
      bodySmall: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
      labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }

  /// Get appropriate text theme for device type
  static TextTheme forDeviceType(
    BuildContext context,
    DeviceType deviceType, {
    bool isKitchenMode = false,
  }) {
    if (isKitchenMode) return kitchenTextTheme(context);

    switch (deviceType) {
      case DeviceType.mobileSmall:
      case DeviceType.mobileMedium:
      case DeviceType.mobileLarge:
        return mobileTextTheme(context);
      case DeviceType.tabletSmall:
      case DeviceType.tabletMedium:
      case DeviceType.tabletLarge:
        return tabletTextTheme(context);
      case DeviceType.desktop:
        return desktopTextTheme(context);
    }
  }

  /// Get appropriate text theme for current screen width
  static TextTheme responsive(BuildContext context, {bool isKitchenMode = false}) {
    final width = MediaQuery.of(context).size.width;
    final deviceType = DeviceType.fromWidth(width);
    return forDeviceType(context, deviceType, isKitchenMode: isKitchenMode);
  }
}

/// Extension on TextTheme for easy access to responsive styles
extension ResponsiveTextTheme on TextTheme {
  /// Apply responsive scaling to this text theme
  TextTheme scale(double scaleFactor) {
    return TextTheme(
      displayLarge: displayLarge?.copyWith(fontSize: (displayLarge!.fontSize ?? 32) * scaleFactor),
      displayMedium: displayMedium?.copyWith(fontSize: (displayMedium!.fontSize ?? 28) * scaleFactor),
      displaySmall: displaySmall?.copyWith(fontSize: (displaySmall!.fontSize ?? 24) * scaleFactor),
      headlineLarge: headlineLarge?.copyWith(fontSize: (headlineLarge!.fontSize ?? 22) * scaleFactor),
      headlineMedium: headlineMedium?.copyWith(fontSize: (headlineMedium!.fontSize ?? 20) * scaleFactor),
      headlineSmall: headlineSmall?.copyWith(fontSize: (headlineSmall!.fontSize ?? 18) * scaleFactor),
      titleLarge: titleLarge?.copyWith(fontSize: (titleLarge!.fontSize ?? 16) * scaleFactor),
      titleMedium: titleMedium?.copyWith(fontSize: (titleMedium!.fontSize ?? 14) * scaleFactor),
      titleSmall: titleSmall?.copyWith(fontSize: (titleSmall!.fontSize ?? 12) * scaleFactor),
      bodyLarge: bodyLarge?.copyWith(fontSize: (bodyLarge!.fontSize ?? 16) * scaleFactor),
      bodyMedium: bodyMedium?.copyWith(fontSize: (bodyMedium!.fontSize ?? 14) * scaleFactor),
      bodySmall: bodySmall?.copyWith(fontSize: (bodySmall!.fontSize ?? 12) * scaleFactor),
      labelLarge: labelLarge?.copyWith(fontSize: (labelLarge!.fontSize ?? 14) * scaleFactor),
      labelMedium: labelMedium?.copyWith(fontSize: (labelMedium!.fontSize ?? 12) * scaleFactor),
      labelSmall: labelSmall?.copyWith(fontSize: (labelSmall!.fontSize ?? 10) * scaleFactor),
    );
  }
}

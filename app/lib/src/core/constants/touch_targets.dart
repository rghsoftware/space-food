/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'dart:io';
import 'breakpoints.dart';

/// Touch target size constants and helpers
class TouchTargets {
  // Platform-specific minimum touch targets
  static const double iosMinium = 44.0; // iOS Human Interface Guidelines
  static const double androidMinimum = 48.0; // Material Design Guidelines
  static const double webMinimum = 44.0; // WCAG 2.1 Level AAA

  // Context-specific touch targets
  static const double standard = 48.0; // Default for most UI elements
  static const double comfortable = 56.0; // Recommended for frequently used buttons
  static const double large = 64.0; // For tablets and important actions
  static const double extraLarge = 72.0; // For large screens

  // Kitchen mode touch targets (for messy hands)
  static const double kitchenMinimum = 56.0;
  static const double kitchenStandard = 72.0;
  static const double kitchenLarge = 96.0;
  static const double kitchenExtraLarge = 120.0;

  // Spacing between touch targets
  static const double minSpacing = 8.0; // Minimum spacing between targets
  static const double standardSpacing = 16.0; // Standard spacing
  static const double kitchenSpacing = 24.0; // Extra spacing for kitchen mode

  /// Get platform-appropriate minimum touch target size
  static double get platformMinimum {
    if (Platform.isIOS) return iosMinium;
    if (Platform.isAndroid) return androidMinimum;
    return webMinimum;
  }

  /// Get touch target size for device type
  static double forDeviceType(DeviceType deviceType, {bool isKitchenMode = false}) {
    if (isKitchenMode) return kitchenStandard;

    switch (deviceType) {
      case DeviceType.mobileSmall:
      case DeviceType.mobileMedium:
      case DeviceType.mobileLarge:
        return standard;
      case DeviceType.tabletSmall:
      case DeviceType.tabletMedium:
      case DeviceType.tabletLarge:
        return comfortable;
      case DeviceType.desktop:
        return standard;
    }
  }

  /// Get touch target size for importance level
  static double forImportance(
    ImportanceLevel importance, {
    required DeviceType deviceType,
    bool isKitchenMode = false,
  }) {
    if (isKitchenMode) {
      switch (importance) {
        case ImportanceLevel.low:
          return kitchenMinimum;
        case ImportanceLevel.medium:
          return kitchenStandard;
        case ImportanceLevel.high:
          return kitchenLarge;
        case ImportanceLevel.critical:
          return kitchenExtraLarge;
      }
    }

    final baseSize = forDeviceType(deviceType);

    switch (importance) {
      case ImportanceLevel.low:
        return baseSize;
      case ImportanceLevel.medium:
        return baseSize + 8.0;
      case ImportanceLevel.high:
        return baseSize + 16.0;
      case ImportanceLevel.critical:
        return baseSize + 24.0;
    }
  }

  /// Get spacing between touch targets
  static double spacing({bool isKitchenMode = false}) {
    return isKitchenMode ? kitchenSpacing : standardSpacing;
  }
}

/// Importance level for UI elements
enum ImportanceLevel {
  low, // Secondary actions, less frequently used
  medium, // Standard actions
  high, // Primary actions, frequently used
  critical, // Emergency actions (e.g., timer stop, delete)
}

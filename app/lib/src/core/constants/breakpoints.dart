/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

/// Breakpoint constants for responsive design
class Breakpoints {
  // Mobile breakpoints
  static const double mobileSmall = 320; // iPhone SE, small Android phones
  static const double mobileMedium = 375; // iPhone 12/13/14
  static const double mobileLarge = 414; // iPhone Plus models

  // Tablet breakpoints
  static const double tabletSmall = 600; // 7" tablets
  static const double tabletMedium = 768; // iPad Mini, 8-10" tablets
  static const double tabletLarge = 1024; // iPad Pro 11", 10-12" tablets

  // Desktop breakpoints
  static const double desktopSmall = 1280; // Small desktop/laptop
  static const double desktopMedium = 1440; // Medium desktop
  static const double desktopLarge = 1920; // Large desktop

  // Special breakpoints
  static const double kitchenDisplay = 800; // Optimal for kitchen counter tablets
}

/// Device type classification based on screen width
enum DeviceType {
  mobileSmall,
  mobileMedium,
  mobileLarge,
  tabletSmall,
  tabletMedium,
  tabletLarge,
  desktop;

  /// Determine device type from screen width
  static DeviceType fromWidth(double width) {
    if (width < Breakpoints.mobileMedium) return DeviceType.mobileSmall;
    if (width < Breakpoints.mobileLarge) return DeviceType.mobileMedium;
    if (width < Breakpoints.tabletSmall) return DeviceType.mobileLarge;
    if (width < Breakpoints.tabletMedium) return DeviceType.tabletSmall;
    if (width < Breakpoints.tabletLarge) return DeviceType.tabletMedium;
    if (width < Breakpoints.desktopSmall) return DeviceType.tabletLarge;
    return DeviceType.desktop;
  }

  /// Check if device is a tablet
  bool get isTablet =>
      this == DeviceType.tabletSmall ||
      this == DeviceType.tabletMedium ||
      this == DeviceType.tabletLarge;

  /// Check if device is a mobile phone
  bool get isMobile =>
      this == DeviceType.mobileSmall ||
      this == DeviceType.mobileMedium ||
      this == DeviceType.mobileLarge;

  /// Check if device is desktop
  bool get isDesktop => this == DeviceType.desktop;

  /// Check if device is suitable for kitchen display
  bool get isKitchenSuitable =>
      this == DeviceType.tabletMedium ||
      this == DeviceType.tabletLarge ||
      this == DeviceType.desktop;

  /// Get minimum comfortable touch target size for this device type
  double get minTouchTarget {
    switch (this) {
      case DeviceType.mobileSmall:
      case DeviceType.mobileMedium:
      case DeviceType.mobileLarge:
        return 48.0; // Material Design minimum
      case DeviceType.tabletSmall:
      case DeviceType.tabletMedium:
      case DeviceType.tabletLarge:
        return 56.0; // Larger for tablets
      case DeviceType.desktop:
        return 44.0; // Standard desktop
    }
  }

  /// Get recommended touch target size for this device type
  double get recommendedTouchTarget {
    switch (this) {
      case DeviceType.mobileSmall:
      case DeviceType.mobileMedium:
      case DeviceType.mobileLarge:
        return 56.0;
      case DeviceType.tabletSmall:
      case DeviceType.tabletMedium:
      case DeviceType.tabletLarge:
        return 64.0;
      case DeviceType.desktop:
        return 48.0;
    }
  }
}

/// Screen orientation
enum ScreenOrientation {
  portrait,
  landscape;

  /// Determine orientation from width and height
  static ScreenOrientation fromSize(double width, double height) {
    return width > height
        ? ScreenOrientation.landscape
        : ScreenOrientation.portrait;
  }
}

/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';

/// Responsive information available to builders
class ResponsiveInfo {
  final double width;
  final double height;
  final DeviceType deviceType;
  final ScreenOrientation orientation;
  final bool isKitchenMode;

  const ResponsiveInfo({
    required this.width,
    required this.height,
    required this.deviceType,
    required this.orientation,
    this.isKitchenMode = false,
  });

  /// Check if in portrait mode
  bool get isPortrait => orientation == ScreenOrientation.portrait;

  /// Check if in landscape mode
  bool get isLandscape => orientation == ScreenOrientation.landscape;

  /// Check if device is mobile
  bool get isMobile => deviceType.isMobile;

  /// Check if device is tablet
  bool get isTablet => deviceType.isTablet;

  /// Check if device is desktop
  bool get isDesktop => deviceType.isDesktop;

  /// Check if device is suitable for kitchen display
  bool get isKitchenSuitable => deviceType.isKitchenSuitable;

  /// Get responsive padding based on device type
  EdgeInsets get standardPadding {
    if (isKitchenMode) return const EdgeInsets.all(24.0);

    if (isMobile) return const EdgeInsets.all(16.0);
    if (isTablet) return const EdgeInsets.all(24.0);
    return const EdgeInsets.all(32.0);
  }

  /// Get responsive content width (max width for readability)
  double get maxContentWidth {
    if (isMobile) return double.infinity;
    if (isTablet) return 768.0;
    return 1200.0;
  }
}

/// Builder function signature for responsive widgets
typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  ResponsiveInfo info,
);

/// Adaptive builder function signature (separate builders for mobile/tablet/desktop)
typedef AdaptiveWidgetBuilder = Widget Function(
  BuildContext context,
  ResponsiveInfo info,
);

/// Responsive builder widget that provides device information
class ResponsiveBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder builder;
  final bool isKitchenMode;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
    this.isKitchenMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final deviceType = DeviceType.fromWidth(width);
        final orientation = ScreenOrientation.fromSize(width, height);

        final info = ResponsiveInfo(
          width: width,
          height: height,
          deviceType: deviceType,
          orientation: orientation,
          isKitchenMode: isKitchenMode,
        );

        return builder(context, info);
      },
    );
  }

  /// Adaptive constructor for different layouts per device type
  static Widget adaptive({
    Key? key,
    required AdaptiveWidgetBuilder mobile,
    AdaptiveWidgetBuilder? tablet,
    AdaptiveWidgetBuilder? desktop,
    bool isKitchenMode = false,
  }) {
    return ResponsiveBuilder(
      key: key,
      isKitchenMode: isKitchenMode,
      builder: (context, info) {
        if (info.isDesktop && desktop != null) {
          return desktop(context, info);
        }
        if (info.isTablet && tablet != null) {
          return tablet(context, info);
        }
        return mobile(context, info);
      },
    );
  }

  /// Value-based responsive helper (returns different values per device type)
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    final deviceType = DeviceType.fromWidth(width);

    if (deviceType.isDesktop && desktop != null) return desktop;
    if (deviceType.isTablet && tablet != null) return tablet;
    return mobile;
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        EdgeInsets padding;

        if (info.isDesktop && desktop != null) {
          padding = desktop!;
        } else if (info.isTablet && tablet != null) {
          padding = tablet!;
        } else if (mobile != null) {
          padding = mobile!;
        } else {
          padding = info.standardPadding;
        }

        return Padding(
          padding: padding,
          child: child,
        );
      },
    );
  }
}

/// Responsive center widget with max width constraint
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        final constrainedMaxWidth = maxWidth ?? info.maxContentWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constrainedMaxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

/// Responsive grid with adaptive column count
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        int columns;
        if (info.isDesktop) {
          columns = desktopColumns;
        } else if (info.isTablet) {
          columns = tabletColumns;
        } else {
          columns = mobileColumns;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          children: children,
        );
      },
    );
  }
}

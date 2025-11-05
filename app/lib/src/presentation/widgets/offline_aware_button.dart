/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/offline_capabilities.dart';
import '../providers/connectivity_provider.dart';

/// Button that adapts behavior based on offline capability and connectivity
class OfflineAwareButton extends ConsumerWidget {
  final OfflineCapability offlineCapability;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final String? offlineMessage;
  final bool elevated;

  const OfflineAwareButton({
    super.key,
    required this.offlineCapability,
    required this.onPressed,
    required this.child,
    this.style,
    this.offlineMessage,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    // Determine if button should be enabled
    final shouldEnable = _shouldEnableButton(isOnline);

    // Create button based on type
    final button = elevated
        ? ElevatedButton(
            onPressed: shouldEnable ? onPressed : null,
            style: style,
            child: child,
          )
        : TextButton(
            onPressed: shouldEnable ? onPressed : null,
            style: style,
            child: child,
          );

    // Wrap with tooltip if offline and requires online
    if (!isOnline && offlineCapability.requiresInternet) {
      return Tooltip(
        message: offlineMessage ?? 'This feature requires internet connection',
        child: button,
      );
    }

    return button;
  }

  bool _shouldEnableButton(bool isOnline) {
    if (onPressed == null) return false;

    switch (offlineCapability) {
      case OfflineCapability.fullyOffline:
      case OfflineCapability.offlineWithCache:
        return true; // Always enabled
      case OfflineCapability.requiresSync:
        return isOnline; // Only enabled when online for initial sync
      case OfflineCapability.requiresOnline:
        return isOnline; // Only enabled when online
    }
  }
}

/// Icon button that adapts behavior based on offline capability and connectivity
class OfflineAwareIconButton extends ConsumerWidget {
  final OfflineCapability offlineCapability;
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final String? offlineMessage;
  final double? iconSize;

  const OfflineAwareIconButton({
    super.key,
    required this.offlineCapability,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.offlineMessage,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    // Determine if button should be enabled
    final shouldEnable = _shouldEnableButton(isOnline);

    // Determine tooltip message
    String? tooltipMessage = tooltip;
    if (!isOnline && offlineCapability.requiresInternet) {
      tooltipMessage =
          offlineMessage ?? 'This feature requires internet connection';
    }

    return IconButton(
      onPressed: shouldEnable ? onPressed : null,
      icon: icon,
      tooltip: tooltipMessage,
      iconSize: iconSize,
    );
  }

  bool _shouldEnableButton(bool isOnline) {
    if (onPressed == null) return false;

    switch (offlineCapability) {
      case OfflineCapability.fullyOffline:
      case OfflineCapability.offlineWithCache:
        return true;
      case OfflineCapability.requiresSync:
      case OfflineCapability.requiresOnline:
        return isOnline;
    }
  }
}

/// Floating action button that adapts based on offline capability
class OfflineAwareFAB extends ConsumerWidget {
  final OfflineCapability offlineCapability;
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final String? offlineMessage;

  const OfflineAwareFAB({
    super.key,
    required this.offlineCapability,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.offlineMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    // Determine if FAB should be enabled
    final shouldEnable = _shouldEnableButton(isOnline);

    // Determine tooltip message
    String? tooltipMessage = tooltip;
    if (!isOnline && offlineCapability.requiresInternet) {
      tooltipMessage =
          offlineMessage ?? 'This feature requires internet connection';
    }

    return FloatingActionButton(
      onPressed: shouldEnable ? onPressed : null,
      tooltip: tooltipMessage,
      backgroundColor:
          shouldEnable ? null : Theme.of(context).disabledColor,
      child: child,
    );
  }

  bool _shouldEnableButton(bool isOnline) {
    if (onPressed == null) return false;

    switch (offlineCapability) {
      case OfflineCapability.fullyOffline:
      case OfflineCapability.offlineWithCache:
        return true;
      case OfflineCapability.requiresSync:
      case OfflineCapability.requiresOnline:
        return isOnline;
    }
  }
}

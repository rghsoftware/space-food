/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/connectivity_provider.dart';

/// Wrapper widget that adds pull-to-refresh functionality
class PullToRefreshWrapper extends ConsumerWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool enabled;

  const PullToRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}

/// Offline-aware pull-to-refresh wrapper that disables when offline
class OfflineAwarePullToRefresh extends ConsumerWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool enableOfflineRefresh;

  const OfflineAwarePullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.enableOfflineRefresh = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    // Only enable refresh if online (unless enableOfflineRefresh is true)
    final enabled = isOnline || enableOfflineRefresh;

    if (!enabled) return child;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}

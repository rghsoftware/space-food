/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/connectivity_service.dart';

// Connectivity service provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

// Connectivity status stream provider
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});

// Current connectivity status provider
final currentConnectivityProvider = Provider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.currentStatus;
});

// Check if online provider
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityStatusProvider);
  return connectivityAsync.maybeWhen(
    data: (status) => status.isOnline,
    orElse: () => false,
  );
});

/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/offline_sync_service.dart';

// Offline sync service provider
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final service = OfflineSyncService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

// Sync status stream provider
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.watch(offlineSyncServiceProvider);
  return service.syncStatusStream;
});

// Queue size provider
final queueSizeProvider = Provider<int>((ref) {
  final service = ref.watch(offlineSyncServiceProvider);
  return service.queueSize;
});

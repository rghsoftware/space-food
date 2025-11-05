/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Network connectivity status
enum ConnectivityStatus {
  online,
  offline,
  poor;

  bool get isOnline => this == ConnectivityStatus.online;
  bool get isOffline => this == ConnectivityStatus.offline;
  bool get isPoor => this == ConnectivityStatus.poor;
}

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _statusController = StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.offline;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    await _updateConnectivity(await _connectivity.checkConnectivity());

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) => _updateConnectivity(results),
    );
  }

  /// Update connectivity status
  Future<void> _updateConnectivity(List<ConnectivityResult> results) async {
    final hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.vpn);

    if (hasConnection) {
      // We have a connection, but is it good?
      // In a real app, you might ping the server to check quality
      _currentStatus = ConnectivityStatus.online;
    } else {
      _currentStatus = ConnectivityStatus.offline;
    }

    _statusController.add(_currentStatus);
  }

  /// Check if we have internet connectivity
  Future<bool> get hasConnection async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.vpn);
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}

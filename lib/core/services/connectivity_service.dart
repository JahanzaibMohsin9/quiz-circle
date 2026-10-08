import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  StreamController<bool>? _connectivityController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;

  /// Get current online status
  bool get isOnline => _isOnline;

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream {
    _connectivityController ??= StreamController<bool>.broadcast();
    return _connectivityController!.stream;
  }

  /// Initialize connectivity monitoring
  Future<void> init() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(result);

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectivityStatus,
        onError: (error) {
          debugPrint(
            'ConnectivityService: Error listening to connectivity - $error',
          );
        },
      );

      debugPrint('ConnectivityService: Initialized successfully');
    } catch (e) {
      debugPrint('ConnectivityService: Failed to initialize - $e');
      rethrow;
    }
  }

  /// Update connectivity status based on result
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Consider online if any connection type is available (except none)
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    debugPrint(
      'ConnectivityService: Status changed - Online: $_isOnline (Results: $results)',
    );

    // Notify listeners if status changed
    if (wasOnline != _isOnline) {
      _connectivityController?.add(_isOnline);
    }
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(result);
      return _isOnline;
    } catch (e) {
      debugPrint('ConnectivityService: Error checking connectivity - $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController?.close();
    debugPrint('ConnectivityService: Disposed');
  }
}

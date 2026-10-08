import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Abstract class for network information
abstract class NetworkInfo {
  /// Checks if the device is connected to the internet
  Future<bool> get isConnected;
  
  /// Stream of connectivity changes
  Stream<ConnectivityResult> get connectivityStream;
}

/// Implementation of NetworkInfo using connectivity_plus
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  
  NetworkInfoImpl(this.connectivity);
  
  @override
  Future<bool> get isConnected async {
    try {
      final results = await connectivity.checkConnectivity();
      return _hasInternetConnection(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }
  
  @override
  Stream<ConnectivityResult> get connectivityStream {
    return connectivity.onConnectivityChanged.map((results) {
      // Return the first non-none result, or none if all are none
      for (final result in results) {
        if (result != ConnectivityResult.none) {
          return result;
        }
      }
      return ConnectivityResult.none;
    });
  }
  
  /// Checks if the connectivity results indicate an internet connection
  bool _hasInternetConnection(List<ConnectivityResult> results) {
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.mobile:
        case ConnectivityResult.vpn:
          return true;
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.other:
        case ConnectivityResult.none:
          continue;
      }
    }
    return false;
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';

/// Provider for CacheService singleton
final cacheServiceProvider = Provider<CacheService>((ref) {
  final service = CacheService();
  // Initialize on first access
  service.init();
  return service;
});

/// Provider for ConnectivityService singleton
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  // Initialize on first access
  service.init();
  // Dispose when provider is disposed
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for online status stream
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.connectivityStream;
});

/// Provider for current online status
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.isOnline;
});

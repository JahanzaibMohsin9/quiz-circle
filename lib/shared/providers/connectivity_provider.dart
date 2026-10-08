import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/network/network_info.dart';

final connectivityProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(Connectivity());
});

final connectivityStreamProvider = StreamProvider<ConnectivityResult>((ref) {
  final networkInfo = ref.watch(connectivityProvider);
  return networkInfo.connectivityStream;
});

final isConnectedProvider = Provider<bool>((ref) {
  final connectivityResult = ref.watch(connectivityStreamProvider);
  return connectivityResult.when(
    data: (result) {
      switch (result) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.mobile:
        case ConnectivityResult.vpn:
          return true;
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.other:
        case ConnectivityResult.none:
          return false;
      }
    },
    loading: () => true, // Assume connected while loading
    error: (_, _) => false,
  );
});
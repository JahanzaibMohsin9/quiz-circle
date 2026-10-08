import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/connectivity_provider.dart';
import '../../data/datasources/firebase_auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final network = ref.watch(connectivityProvider);
  final remote = FirebaseAuthRemoteDataSource();
  return AuthRepositoryImpl(networkInfo: network, remote: remote);
});


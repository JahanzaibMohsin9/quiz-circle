import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../shared/providers/connectivity_provider.dart';
import '../../data/datasources/firestore_admin_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final network = ref.watch(connectivityProvider);
  final remote = FirestoreAdminDataSource();
  final cache = ref.watch(cacheServiceProvider);
  return AdminRepositoryImpl(
    networkInfo: network,
    remote: remote,
    cache: cache,
  );
});

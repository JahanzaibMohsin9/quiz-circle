import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/analytics.dart';
import '../repositories/admin_repository.dart';

class GetTopPerformingUsers implements UseCase<List<UserAnalytics>, GetTopPerformingUsersParams> {
  final AdminRepository repository;
  
  GetTopPerformingUsers(this.repository);

  @override
  Future<Either<Failure, List<UserAnalytics>>> call(GetTopPerformingUsersParams params) {
    return repository.getTopPerformingUsers(params.limit);
  }
}

class GetTopPerformingUsersParams {
  final int limit;
  
  const GetTopPerformingUsersParams({
    required this.limit,
  });
}
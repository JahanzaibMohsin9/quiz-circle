import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recent_activity.dart';
import '../repositories/admin_repository.dart';

class GetRecentActivity
    implements UseCase<List<RecentActivity>, GetRecentActivityParams> {
  final AdminRepository repository;

  GetRecentActivity(this.repository);

  @override
  Future<Either<Failure, List<RecentActivity>>> call(
    GetRecentActivityParams params,
  ) {
    return repository.getRecentActivity(params.limit);
  }
}

class GetRecentActivityParams {
  final int limit;

  const GetRecentActivityParams({this.limit = 10});
}

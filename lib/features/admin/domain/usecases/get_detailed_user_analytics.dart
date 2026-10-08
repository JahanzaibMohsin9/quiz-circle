import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/analytics.dart';
import '../repositories/admin_repository.dart';

class GetDetailedUserAnalytics implements UseCase<UserAnalytics, GetDetailedUserAnalyticsParams> {
  final AdminRepository repository;
  
  GetDetailedUserAnalytics(this.repository);

  @override
  Future<Either<Failure, UserAnalytics>> call(GetDetailedUserAnalyticsParams params) {
    return repository.getDetailedUserAnalytics(params.userId);
  }
}

class GetDetailedUserAnalyticsParams {
  final String userId;
  
  const GetDetailedUserAnalyticsParams({
    required this.userId,
  });
}
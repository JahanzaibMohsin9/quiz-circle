import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/analytics.dart';
import '../repositories/admin_repository.dart';

class GetSystemAnalytics implements UseCase<SystemAnalytics, GetSystemAnalyticsParams> {
  final AdminRepository repository;
  
  GetSystemAnalytics(this.repository);

  @override
  Future<Either<Failure, SystemAnalytics>> call(GetSystemAnalyticsParams params) {
    return repository.getSystemAnalytics(params.dateRange);
  }
}

class GetSystemAnalyticsParams {
  final DateRange? dateRange;
  
  const GetSystemAnalyticsParams({
    this.dateRange,
  });
}
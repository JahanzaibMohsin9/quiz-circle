import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_repository.dart';

class GetUserAnalytics implements UseCase<AdminUser, GetUserAnalyticsParams> {
  final AdminRepository repository;
  GetUserAnalytics(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(GetUserAnalyticsParams params) {
    return repository.getUserAnalytics(params.userId);
  }
}

class GetUserAnalyticsParams {
  final String userId;
  const GetUserAnalyticsParams(this.userId);
}


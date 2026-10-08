import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/analytics.dart';
import '../repositories/admin_repository.dart';

class GetQuizAnalytics implements UseCase<QuizAnalytics, GetQuizAnalyticsParams> {
  final AdminRepository repository;
  
  GetQuizAnalytics(this.repository);

  @override
  Future<Either<Failure, QuizAnalytics>> call(GetQuizAnalyticsParams params) {
    return repository.getQuizAnalytics(params.quizId, params.dateRange);
  }
}

class GetQuizAnalyticsParams {
  final String quizId;
  final DateRange? dateRange;
  
  const GetQuizAnalyticsParams({
    required this.quizId,
    this.dateRange,
  });
}
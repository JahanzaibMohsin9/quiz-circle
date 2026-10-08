import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/analytics.dart';
import '../repositories/admin_repository.dart';

class GetTopPerformingQuizzes implements UseCase<List<QuizAnalytics>, GetTopPerformingQuizzesParams> {
  final AdminRepository repository;
  
  GetTopPerformingQuizzes(this.repository);

  @override
  Future<Either<Failure, List<QuizAnalytics>>> call(GetTopPerformingQuizzesParams params) {
    return repository.getTopPerformingQuizzes(params.limit);
  }
}

class GetTopPerformingQuizzesParams {
  final int limit;
  
  const GetTopPerformingQuizzesParams({
    required this.limit,
  });
}
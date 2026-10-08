import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/quiz_repository.dart';

/// Use case for getting global leaderboard across all quizzes
class GetGlobalLeaderboard
    implements UseCase<List<Map<String, dynamic>>, NoParams> {
  final QuizRepository repository;

  GetGlobalLeaderboard(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(
    NoParams params,
  ) async {
    return await repository.getGlobalLeaderboard();
  }
}

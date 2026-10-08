import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/quiz_repository.dart';

class GetLeaderboardParams extends Equatable {
  final String quizId;

  const GetLeaderboardParams({required this.quizId});

  @override
  List<Object?> get props => [quizId];
}

class GetLeaderboard implements UseCase<List<Map<String, dynamic>>, GetLeaderboardParams> {
  final QuizRepository repo;
  
  GetLeaderboard(this.repo);
  
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetLeaderboardParams params) {
    return repo.getLeaderboard(params.quizId);
  }
}
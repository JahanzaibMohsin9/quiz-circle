import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/submission.dart';
import '../repositories/quiz_repository.dart';

class GetSubmissionsParams extends Equatable {
  final String userId;

  const GetSubmissionsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class GetSubmissions implements UseCase<List<Submission>, GetSubmissionsParams> {
  final QuizRepository repo;
  
  GetSubmissions(this.repo);
  
  @override
  Future<Either<Failure, List<Submission>>> call(GetSubmissionsParams params) {
    return repo.getSubmissions(params.userId);
  }
}
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../../../quiz/domain/entities/quiz_permissions.dart';
import '../../../quiz/domain/entities/quiz_metadata.dart';
import '../../../quiz/domain/entities/question.dart';
import '../repositories/admin_repository.dart';

class UpdateQuiz implements UseCase<Quiz, UpdateQuizParams> {
  final AdminRepository repository;
  UpdateQuiz(this.repository);

  @override
  Future<Either<Failure, Quiz>> call(UpdateQuizParams params) {
    return repository.updateQuiz(
      id: params.id,
      title: params.title,
      description: params.description,
      timeLimitMinutes: params.timeLimitMinutes,
      questions: params.questions,
      questionsPerAttempt: params.questionsPerAttempt,
      randomizeQuestions: params.randomizeQuestions,
      permissions: params.permissions,
      metadata: params.metadata,
    );
  }
}

class UpdateQuizParams {
  final String id;
  final String title;
  final String description;
  final int timeLimitMinutes;
  final List<Question> questions;
  final int questionsPerAttempt;
  final bool randomizeQuestions;
  final QuizPermissions? permissions;
  final QuizMetadata? metadata;

  const UpdateQuizParams(
    this.id, 
    this.title, 
    this.description, 
    this.timeLimitMinutes, 
    this.questions,
    {
    this.questionsPerAttempt = 0,
    this.randomizeQuestions = false,
    this.permissions, 
    this.metadata
    }
  );
}

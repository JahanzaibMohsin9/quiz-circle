import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/admin_repository.dart';

class UploadQuestionImage implements UseCase<String, UploadQuestionImageParams> {
  final AdminRepository repository;
  UploadQuestionImage(this.repository);

  @override
  Future<Either<Failure, String>> call(UploadQuestionImageParams params) {
    return repository.uploadQuestionImage(params.questionId, params.filePath);
  }
}

class UploadQuestionImageParams {
  final String questionId;
  final String filePath;
  const UploadQuestionImageParams(this.questionId, this.filePath);
}


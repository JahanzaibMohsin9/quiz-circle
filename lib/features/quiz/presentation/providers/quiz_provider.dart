import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/quiz.dart';
import 'quiz_usecases.dart';

final quizListProvider = FutureProvider<List<Quiz>>((ref) async {
  final usecase = ref.watch(getQuizzesUseCaseProvider);
  final result = await usecase.call(ref.watch(noParamsProvider));
  return result.fold(
    (failure) {
      throw Exception(failure.message);
    },
    (quizzes) {
      return quizzes;
    },
  );
});

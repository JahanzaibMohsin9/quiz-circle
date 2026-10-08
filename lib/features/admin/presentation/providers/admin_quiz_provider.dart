import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../../quiz/domain/entities/quiz_permissions.dart';
import '../../../quiz/domain/entities/quiz_metadata.dart';
import 'admin_usecases.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/create_quiz.dart';
import '../../domain/usecases/update_quiz.dart';
import '../../domain/usecases/delete_quiz.dart';
import '../../domain/usecases/set_quiz_active.dart';

class AdminQuizState {
  final List<Quiz> quizzes;
  final bool isLoading;
  final String? error;
  const AdminQuizState({this.quizzes = const [], this.isLoading = false, this.error});

  AdminQuizState copyWith({List<Quiz>? quizzes, bool? isLoading, String? error}) {
    return AdminQuizState(quizzes: quizzes ?? this.quizzes, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class AdminQuizController extends Notifier<AdminQuizState> {
  @override
  AdminQuizState build() {
    // Load quizzes when provider is first created
    Future.microtask(() => loadQuizzes());
    return const AdminQuizState();
  }

  Future<void> loadQuizzes() async {
    state = state.copyWith(isLoading: true);
    final usecase = ref.read(getAdminQuizzesUseCaseProvider);
    final result = await usecase.call(const NoParams());
    state = result.fold(
      (l) => state.copyWith(isLoading: false, error: l.message),
      (quizzes) => AdminQuizState(quizzes: quizzes),
    );
  }

  Future<void> createQuiz(
    String title, 
    String description, 
    int timeLimitMinutes, 
    List<Question> questions, {
    int questionsPerAttempt = 0,
    bool randomizeQuestions = false,
    QuizPermissions? permissions,
    QuizMetadata? metadata,
  }) async {
    state = state.copyWith(isLoading: true);
    final usecase = ref.read(createQuizUseCaseProvider);
    final result = await usecase.call(CreateQuizParams(
      title, 
      description, 
      timeLimitMinutes, 
      questions,
      questionsPerAttempt: questionsPerAttempt,
      randomizeQuestions: randomizeQuestions,
      permissions: permissions,
      metadata: metadata,
    ));
    state = result.fold(
      (l) => state.copyWith(isLoading: false, error: l.message),
      (_) => state.copyWith(isLoading: false),
    );
    await loadQuizzes();
  }

  Future<void> updateQuiz(
    String id, 
    String title, 
    String description, 
    int timeLimitMinutes, 
    List<Question> questions, {
    int questionsPerAttempt = 0,
    bool randomizeQuestions = false,
    QuizPermissions? permissions,
    QuizMetadata? metadata,
  }) async {
    state = state.copyWith(isLoading: true);
    final usecase = ref.read(updateQuizUseCaseProvider);
    final result = await usecase.call(UpdateQuizParams(
      id, 
      title, 
      description, 
      timeLimitMinutes, 
      questions,
      questionsPerAttempt: questionsPerAttempt,
      randomizeQuestions: randomizeQuestions,
      permissions: permissions,
      metadata: metadata,
    ));
    state = result.fold(
      (l) => state.copyWith(isLoading: false, error: l.message),
      (_) => state.copyWith(isLoading: false),
    );
    await loadQuizzes();
  }

  Future<void> setActive(String id, bool isActive) async {
    state = state.copyWith(isLoading: true);
    final usecase = ref.read(setQuizActiveUseCaseProvider);
    final result = await usecase.call(SetQuizActiveParams(id, isActive));
    state = result.fold(
      (l) => state.copyWith(isLoading: false, error: l.message),
      (_) => state.copyWith(isLoading: false),
    );
    await loadQuizzes();
  }

  Future<void> deleteQuiz(String id) async {
    state = state.copyWith(isLoading: true);
    final usecase = ref.read(deleteQuizUseCaseProvider);
    final result = await usecase.call(DeleteQuizParams(id));
    state = result.fold(
      (l) => state.copyWith(isLoading: false, error: l.message),
      (_) => state.copyWith(isLoading: false),
    );
    await loadQuizzes();
  }
}

final adminQuizProvider = NotifierProvider<AdminQuizController, AdminQuizState>(() {
  return AdminQuizController();
});

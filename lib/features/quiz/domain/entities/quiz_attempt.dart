import 'package:equatable/equatable.dart';
import 'question.dart';

class QuizAttempt extends Equatable {
  final String id;
  final String quizId;
  final String quizTitle;
  final List<Question> questions;
  final Map<String, String> selectedAnswers; // questionId -> selectedAnswer
  final int currentQuestionIndex;
  final int timeLimitMinutes;
  final int timeRemainingSeconds;
  final DateTime startTime;
  final bool isSubmitted;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.questions,
    required this.selectedAnswers,
    required this.currentQuestionIndex,
    required this.timeLimitMinutes,
    required this.timeRemainingSeconds,
    required this.startTime,
    this.isSubmitted = false,
  });

  QuizAttempt copyWith({
    String? id,
    String? quizId,
    String? quizTitle,
    List<Question>? questions,
    Map<String, String>? selectedAnswers,
    int? currentQuestionIndex,
    int? timeLimitMinutes,
    int? timeRemainingSeconds,
    DateTime? startTime,
    bool? isSubmitted,
  }) {
    return QuizAttempt(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      quizTitle: quizTitle ?? this.quizTitle,
      questions: questions ?? this.questions,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      startTime: startTime ?? this.startTime,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }

  Question? get currentQuestion {
    if (currentQuestionIndex >= 0 && currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    }
    return null;
  }

  bool get isFirstQuestion => currentQuestionIndex == 0;
  
  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;

  int get answeredQuestionsCount => selectedAnswers.length;

  double get progressPercentage {
    if (questions.isEmpty) return 0.0;
    return (currentQuestionIndex + 1) / questions.length;
  }

  @override
  List<Object?> get props => [
        id,
        quizId,
        quizTitle,
        questions,
        selectedAnswers,
        currentQuestionIndex,
        timeLimitMinutes,
        timeRemainingSeconds,
        startTime,
        isSubmitted,
      ];
}
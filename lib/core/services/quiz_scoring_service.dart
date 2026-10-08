import '../../../features/quiz/domain/entities/question.dart';

/// Centralized quiz scoring service to ensure consistency between client and server
/// calculations. This eliminates duplicate logic and prevents score mismatches.
class QuizScoringService {
  /// Calculates the total score and number of correct answers for a quiz attempt.
  ///
  /// Handles two formats for [Question.correctAnswer]:
  /// - 1-based index string (e.g., "2" means second option)
  /// - Full option text (e.g., "Paris")
  ///
  /// Returns a record with:
  /// - score: Total points earned
  /// - correctCount: Number of questions answered correctly
  static ({int score, int correctCount}) calculateScore({
    required List<Question> questions,
    required Map<String, String> userAnswers,
  }) {
    int score = 0;
    int correctCount = 0;

    for (final question in questions) {
      final userAnswerLetter = userAnswers[question.id];
      if (userAnswerLetter == null) continue;

      // Convert letter (A, B, C, D) to 0-based index
      final optionIndex = userAnswerLetter.codeUnitAt(0) - 65;
      if (optionIndex < 0 || optionIndex >= question.options.length) continue;

      final userAnswerText = question.options[optionIndex];
      final isCorrect = _isAnswerCorrect(
        question: question,
        userAnswerText: userAnswerText,
        userAnswerIndex: optionIndex,
      );

      if (isCorrect) {
        score += question.points;
        correctCount++;
      }
    }

    return (score: score, correctCount: correctCount);
  }

  /// Checks if a user's answer is correct.
  ///
  /// Handles both correctAnswer formats:
  /// - 1-based index: "1", "2", "3", "4" (compares index)
  /// - Full text: "Paris", "Rome", etc. (compares text)
  static bool _isAnswerCorrect({
    required Question question,
    required String userAnswerText,
    required int userAnswerIndex,
  }) {
    // Try parsing correctAnswer as 1-based index
    final correctAnswerIndex = int.tryParse(question.correctAnswer);

    if (correctAnswerIndex != null &&
        correctAnswerIndex >= 1 &&
        correctAnswerIndex <= question.options.length) {
      // correctAnswer is 1-based index format
      return userAnswerIndex == (correctAnswerIndex - 1);
    } else {
      // correctAnswer is full text format
      return userAnswerText == question.correctAnswer;
    }
  }

  /// Validates if a correctAnswer value is valid for the given options.
  /// Used during quiz creation to ensure questions can be answered correctly.
  static bool isValidCorrectAnswer(String correctAnswer, List<String> options) {
    final index = int.tryParse(correctAnswer);
    if (index != null) {
      // Must be valid 1-based index
      return index >= 1 && index <= options.length;
    }
    // Must match one of the options exactly
    return options.contains(correctAnswer);
  }
}

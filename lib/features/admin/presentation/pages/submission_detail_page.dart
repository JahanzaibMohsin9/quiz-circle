import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/timestamp_parser.dart';
import '../../../../shared/widgets/common/error_state_widget.dart';
import '../../../quiz/domain/entities/submission.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../../quiz/data/models/question_model.dart';

/// Provider to fetch submission by ID directly from Firestore
final submissionByIdProvider = FutureProvider.family<Submission?, String>((
  ref,
  submissionId,
) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('submissions')
        .doc(submissionId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return Submission(
      id: doc.id,
      quizId: data['quizId'] as String,
      userId: data['userId'] as String,
      score: data['score'] as int,
      totalQuestions: data['totalQuestions'] as int,
      percentage: (data['percentage'] as num).toDouble(),
      submittedAt: TimestampParser.parse(data['submittedAt']),
      quizTitle: data['quizTitle'] as String? ?? 'Unknown Quiz',
      correctAnswersCount: data['correctAnswersCount'] as int? ?? 0,
      answers: Map<String, String>.from(data['answers'] as Map? ?? {}),
      timeTakenSeconds: data['timeTakenSeconds'] as int,
    );
  } catch (e) {
    return null;
  }
});

/// Provider to fetch questions for a quiz directly from Firestore
final questionsForSubmissionProvider =
    FutureProvider.family<List<Question>, String>((ref, quizId) async {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(quizId)
            .collection('questions')
            .orderBy('order')
            .get();

        return snapshot.docs
            .map((doc) => QuestionModel.fromJson(doc.data()).toDomain())
            .toList();
      } catch (e) {
        return [];
      }
    });

/// Provider to fetch user name by userId from Firestore
final userNameProvider = FutureProvider.family<String, String>((
  ref,
  userId,
) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!doc.exists) return 'Unknown User';

    final data = doc.data();
    return data?['name'] as String? ?? 'Unknown User';
  } catch (e) {
    return 'Unknown User';
  }
});

class SubmissionDetailPage extends ConsumerWidget {
  final String submissionId;
  final String? quizId;

  const SubmissionDetailPage({
    super.key,
    required this.submissionId,
    this.quizId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionAsync = ref.watch(submissionByIdProvider(submissionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Submission Details')),
      body: submissionAsync.when(
        data: (submission) {
          if (submission == null) {
            return ErrorStateWidget(
              message: 'Submission not found',
              errorType: ErrorType.notFound,
              onRetry: () =>
                  ref.invalidate(submissionByIdProvider(submissionId)),
            );
          }

          final questionsAsync = ref.watch(
            questionsForSubmissionProvider(submission.quizId),
          );

          return questionsAsync.when(
            data: (questions) {
              final userNameAsync = ref.watch(
                userNameProvider(submission.userId),
              );
              
              return userNameAsync.when(
                data: (userName) => _buildContent(
                  context,
                  submission,
                  questions,
                  userName,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildContent(
                  context,
                  submission,
                  questions,
                  'Unknown User',
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => ErrorStateWidget(
              message: 'Failed to load questions',
              errorType: ErrorType.network,
              onRetry: () => ref.invalidate(
                questionsForSubmissionProvider(submission.quizId),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateWidget(
          message: 'Failed to load submission',
          errorType: ErrorType.network,
          onRetry: () => ref.invalidate(submissionByIdProvider(submissionId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Submission submission,
    List<Question> questions,
    String userName,
  ) {
    final scorePercentage = submission.percentage.round();
    final scoreColor = scorePercentage >= 80
        ? AppColors.success
        : scorePercentage >= 60
        ? AppColors.warning
        : AppColors.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Summary Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: scoreColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scoreColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    submission.quizTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreStat(
                        context,
                        'Score',
                        '${submission.score}/${submission.totalQuestions}',
                        Icons.scoreboard_rounded,
                        scoreColor,
                      ),
                      Container(width: 1, height: 60, color: AppColors.border),
                      _buildScoreStat(
                        context,
                        'Percentage',
                        '$scorePercentage%',
                        Icons.percent_rounded,
                        scoreColor,
                      ),
                      Container(width: 1, height: 60, color: AppColors.border),
                      _buildScoreStat(
                        context,
                        'Time',
                        _formatDuration(submission.timeTakenSeconds),
                        Icons.access_time_rounded,
                        AppColors.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submitted: ${_formatDateTime(submission.submittedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Questions & Answers Section
          Text(
            'Question Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          // Build question cards
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final userAnswer = submission.answers[question.id];

            return _buildQuestionCard(context, index + 1, question, userAnswer);
          }),
        ],
      ),
    );
  }

  Widget _buildScoreStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    int questionNumber,
    Question question,
    String? userAnswer,
  ) {
    // Determine if user answered correctly
    final isCorrect =
        userAnswer != null && _isAnswerCorrect(question, userAnswer);
    final cardColor = userAnswer == null
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : isCorrect
        ? AppColors.success
        : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Q$questionNumber',
                    style: TextStyle(
                      color: cardColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.questionText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  userAnswer == null
                      ? Icons.help_outline_rounded
                      : isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: cardColor,
                  size: 28,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Answer Options
            ...question.options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final optionText = entry.value;
              final optionLetter = String.fromCharCode(
                65 + optionIndex,
              ); // A, B, C, D

              final isUserAnswer = userAnswer == optionLetter;
              final isCorrectAnswer = _isCorrectOption(question, optionIndex);

              Color backgroundColor;
              Color textColor;
              IconData? trailingIcon;

              if (isUserAnswer && isCorrectAnswer) {
                // User selected correct answer
                backgroundColor = AppColors.success.withValues(alpha: 0.1);
                textColor = AppColors.success;
                trailingIcon = Icons.check_circle;
              } else if (isUserAnswer && !isCorrectAnswer) {
                // User selected wrong answer
                backgroundColor = AppColors.error.withValues(alpha: 0.1);
                textColor = AppColors.error;
                trailingIcon = Icons.cancel;
              } else if (!isUserAnswer && isCorrectAnswer) {
                // Correct answer (not selected by user)
                backgroundColor = AppColors.success.withValues(alpha: 0.05);
                textColor = AppColors.success;
                trailingIcon = Icons.check_circle_outline;
              } else {
                // Other options
                backgroundColor = Colors.transparent;
                textColor = Theme.of(context).colorScheme.onSurfaceVariant;
                trailingIcon = null;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isUserAnswer || isCorrectAnswer
                        ? textColor.withValues(alpha: 0.3)
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        optionLetter,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionText,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: isUserAnswer || isCorrectAnswer
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(trailingIcon, color: textColor, size: 20),
                    ],
                  ],
                ),
              );
            }),

            // Show "Not Answered" if user didn't answer
            if (userAnswer == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '⚠️ Question not answered',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isAnswerCorrect(Question question, String userAnswer) {
    // Convert letter (A, B, C, D) to 0-based index
    final optionIndex = userAnswer.codeUnitAt(0) - 65;
    if (optionIndex < 0 || optionIndex >= question.options.length) return false;

    final userAnswerText = question.options[optionIndex];

    // Try parsing correctAnswer as 1-based index
    final correctAnswerIndex = int.tryParse(question.correctAnswer);

    if (correctAnswerIndex != null &&
        correctAnswerIndex >= 1 &&
        correctAnswerIndex <= question.options.length) {
      // correctAnswer is 1-based index format
      return optionIndex == (correctAnswerIndex - 1);
    } else {
      // correctAnswer is full text format
      return userAnswerText == question.correctAnswer;
    }
  }

  bool _isCorrectOption(Question question, int optionIndex) {
    // Try parsing correctAnswer as 1-based index
    final correctAnswerIndex = int.tryParse(question.correctAnswer);

    if (correctAnswerIndex != null &&
        correctAnswerIndex >= 1 &&
        correctAnswerIndex <= question.options.length) {
      // correctAnswer is 1-based index format
      return optionIndex == (correctAnswerIndex - 1);
    } else {
      // correctAnswer is full text format
      return question.options[optionIndex] == question.correctAnswer;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

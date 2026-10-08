import 'package:flutter/material.dart';
import '../../../features/quiz/domain/entities/question.dart';
import 'answer_option.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final int questionNumber; // Add question number parameter
  final String? selectedAnswer;
  final Function(String) onAnswerSelected;
  final bool showResult;
  final bool isSubmitted;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber, // Make it required
    this.selectedAnswer,
    required this.onAnswerSelected,
    this.showResult = false,
    this.isSubmitted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question $questionNumber',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.questionText,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (question.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  question.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            ..._buildOptions(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptions(BuildContext context) {
    return question.options.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;
      final optionLetter = String.fromCharCode(65 + index); // A, B, C, D, etc.

      // CRITICAL FIX: Never show correct/incorrect indicators during quiz
      // Students should not see results before submission to prevent answer changes
      // The correctness check has been removed entirely

      return AnswerOption(
        text: option,
        value: optionLetter,
        selectedValue: selectedAnswer,
        isEnabled: !isSubmitted,
        onChanged: (value) {
          if (!isSubmitted && value != null) {
            onAnswerSelected(value);
          }
        },
      );
    }).toList();
  }
}

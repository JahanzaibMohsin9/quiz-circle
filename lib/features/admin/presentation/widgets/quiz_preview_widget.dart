import 'package:flutter/material.dart';
import '../../data/models/csv_quiz_import.dart';

class QuizPreviewWidget extends StatelessWidget {
  final CsvQuizImport quizImport;

  const QuizPreviewWidget({super.key, required this.quizImport});

  @override
  Widget build(BuildContext context) {
    final metadata = quizImport.metadata;
    final questions = quizImport.questions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Preview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                metadata.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(metadata.description),
            ),
            Row(
              children: [
                _buildBadge(
                  context,
                  '${metadata.timeLimitMinutes} mins',
                  Icons.timer,
                ),
                const SizedBox(width: 8),
                _buildBadge(context, metadata.category.name, Icons.category),
                const SizedBox(width: 8),
                _buildBadge(context, metadata.difficulty.name, Icons.speed),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Questions (${questions.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                return ExpansionTile(
                  title: Text(question.questionText),
                  subtitle: Text('${question.points} points'),
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...question.options.map((option) {
                            final isCorrect = option == question.correctAnswer;
                            return ListTile(
                              dense: true,
                              title: Text(option),
                              leading: Icon(
                                isCorrect
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: isCorrect
                                    ? Colors.green
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            );
                          }),
                          if (question.explanation != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Explanation: ${question.explanation}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

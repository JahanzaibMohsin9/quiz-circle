import 'package:flutter/material.dart';
import '../../data/models/csv_validation_error.dart';

class CsvValidationResultWidget extends StatelessWidget {
  final List<CsvValidationError> errors;

  const CsvValidationResultWidget({
    super.key,
    required this.errors,
  });

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Validation Errors (${errors.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: errors.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final error = errors[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    radius: 12,
                    child: Text(
                      '${error.rowNumber}',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    error.message,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                  subtitle: Text(
                    'Field: ${error.field} • Type: ${error.type.name}',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

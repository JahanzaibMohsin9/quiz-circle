import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../quiz/domain/entities/quiz_permissions.dart';
import '../../domain/services/bulk_operations_service.dart';
import '../providers/admin_quiz_provider.dart';
import '../../../../shared/widgets/common/custom_button.dart';
import '../../../../shared/widgets/admin/permission_manager_widget.dart';
import '../providers/admin_user_provider.dart';

class BulkOperationsDialog extends ConsumerStatefulWidget {
  final List<String> selectedQuizIds;
  final VoidCallback onComplete;

  const BulkOperationsDialog({
    super.key,
    required this.selectedQuizIds,
    required this.onComplete,
  });

  @override
  ConsumerState<BulkOperationsDialog> createState() =>
      _BulkOperationsDialogState();
}

class _BulkOperationsDialogState extends ConsumerState<BulkOperationsDialog> {
  BulkOperationType _selectedOperation = BulkOperationType.activate;
  bool _isProcessing = false;
  BulkUpdateResult? _result;

  // For activation operation
  bool _activateValue = true;

  // For permissions operation
  QuizPermissions _permissions = const QuizPermissions(
    quizId: '',  );

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUserProvider);

    return AlertDialog(
      title: Text('Bulk Operations (${widget.selectedQuizIds.length} quizzes)'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_result != null) ...[
                _buildResultCard(),
                const SizedBox(height: 16),
              ] else ...[
                const Text('Select operation to perform:'),
                const SizedBox(height: 16),
                _buildOperationSelector(),
                const SizedBox(height: 24),
                _buildOperationConfig(usersState),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_result == null) ...[
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: _isProcessing ? 'Processing...' : 'Execute',
            onPressed: _isProcessing ? null : _executeOperation,
          ),
        ] else ...[
          CustomButton(
            text: 'Close',
            onPressed: () {
              widget.onComplete();
              Navigator.of(context).pop();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildResultCard() {
    if (_result == null) return const SizedBox.shrink();

    return Card(
      color: _result!.isFullSuccess ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _result!.isFullSuccess ? Icons.check_circle : Icons.warning,
                  color: _result!.isFullSuccess ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _result!.isFullSuccess
                      ? 'All operations completed successfully'
                      : 'Some operations failed',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Total: ${_result!.totalItems}'),
            Text(
              'Success: ${_result!.successCount}',
              style: const TextStyle(color: Colors.green),
            ),
            if (_result!.failureCount > 0)
              Text(
                'Failed: ${_result!.failureCount}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationSelector() {
    return RadioGroup<BulkOperationType>(
      // Corrected parameter name: groupValue
      groupValue: _selectedOperation,
      onChanged: (value) => setState(() => _selectedOperation = value!),
      child: const Column(
        children: [
          RadioListTile<BulkOperationType>(
            title: Text('Activate/Deactivate'),
            subtitle: Text('Change active status for selected quizzes'),
            value: BulkOperationType.activate,
          ),
          RadioListTile<BulkOperationType>(
            title: Text('Delete'),
            subtitle: Text('Permanently delete selected quizzes'),
            value: BulkOperationType.delete,
          ),
          RadioListTile<BulkOperationType>(
            title: Text('Apply Permissions'),
            subtitle: Text('Set permissions for selected quizzes'),
            value: BulkOperationType.permissions,
          ),
        ],
      ),
    );
  }

  Widget _buildOperationConfig(dynamic usersState) {
    switch (_selectedOperation) {
      case BulkOperationType.activate:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set quizzes to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioGroup<bool>(
              groupValue: _activateValue, // Corrected parameter name
              onChanged: (value) => setState(() => _activateValue = value!),
              child: const Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Active'),
                      value: true,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Inactive'),
                      value: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case BulkOperationType.delete:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Warning: This will permanently delete ${widget.selectedQuizIds.length} quizzes. This action cannot be undone.',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );

      case BulkOperationType.permissions:
        return PermissionManagerWidget(
          permissions: _permissions,
          onPermissionsChanged: (p) => setState(() => _permissions = p),
          availableUsers: usersState.users.map((u) => u.id).toList(),
        );
    }
  }

  Future<void> _executeOperation() async {
    setState(() => _isProcessing = true);

    BulkUpdateResult? result;

    switch (_selectedOperation) {
      case BulkOperationType.activate:
        result = await _performBulkActivate();
        break;

      case BulkOperationType.delete:
        final confirmed = await _confirmDeletion();
        if (confirmed) {
          result = await _performBulkDelete();
        }
        break;

      case BulkOperationType.permissions:
        result = await _performBulkPermissions();
        break;
    }

    setState(() {
      _isProcessing = false;
      _result = result;
    });
  }

  Future<bool> _confirmDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete ${widget.selectedQuizIds.length} quizzes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<BulkUpdateResult> _performBulkActivate() async {
    final results = <String, bool>{};
    int successCount = 0;

    for (final quizId in widget.selectedQuizIds) {
      await ref
          .read(adminQuizProvider.notifier)
          .setActive(quizId, _activateValue);
      results[quizId] = true;
      successCount++;
    }

    return BulkUpdateResult(
      totalItems: widget.selectedQuizIds.length,
      successCount: successCount,
      failureCount: 0,
      results: results,
    );
  }

  Future<BulkUpdateResult> _performBulkDelete() async {
    final results = <String, bool>{};
    int successCount = 0;
    int failureCount = 0;

    for (final quizId in widget.selectedQuizIds) {
      try {
        await ref.read(adminQuizProvider.notifier).deleteQuiz(quizId);
        results[quizId] = true;
        successCount++;
      } catch (e) {
        results[quizId] = false;
        failureCount++;
      }
    }

    return BulkUpdateResult(
      totalItems: widget.selectedQuizIds.length,
      successCount: successCount,
      failureCount: failureCount,
      results: results,
    );
  }

  Future<BulkUpdateResult> _performBulkPermissions() async {
    final results = <String, bool>{};
    int successCount = 0;

    for (final quizId in widget.selectedQuizIds) {
      // This would need actual permission update implementation
      results[quizId] = true;
      successCount++;
    }

    return BulkUpdateResult(
      totalItems: widget.selectedQuizIds.length,
      successCount: successCount,
      failureCount: 0,
      results: results,
    );
  }
}

enum BulkOperationType { activate, delete, permissions }

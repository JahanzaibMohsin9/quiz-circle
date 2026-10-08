import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/admin_user_provider.dart';

class ManageUsersPage extends ConsumerWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminUserProvider);
    final controller = ref.read(adminUserProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadUsers(),
        child: ListView.builder(
          itemCount: state.users.length,
          itemBuilder: (context, index) {
            final user = state.users[index];
            return Card(
              child: ListTile(
                title: Text(user.name),
                subtitle: Text(
                  '${user.email} • ${user.role.name}${user.isBlocked ? ' • Blocked' : ''}\nScore: ${user.totalScore} • Avg: ${user.averagePercentage.toStringAsFixed(1)}%',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: user.role.name,
                      items: const [
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Student'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (v) {
                        if (v != null) controller.updateUserRole(user.id, v);
                      },
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: user.isBlocked ? 'Unblock User' : 'Block User',
                      child: IconButton(
                        icon: Icon(
                          user.isBlocked ? Icons.lock_open : Icons.lock,
                          color: user.isBlocked
                              ? Colors.orange
                              : Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _showBlockConfirmation(
                          context,
                          user.id,
                          user.name,
                          user.isBlocked,
                          controller,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showBlockConfirmation(
    BuildContext context,
    String userId,
    String userName,
    bool isCurrentlyBlocked,
    dynamic controller,
  ) async {
    final action = isCurrentlyBlocked ? 'Unblock' : 'Block';
    final actionLower = action.toLowerCase();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isCurrentlyBlocked ? Icons.lock_open : Icons.lock,
              color: isCurrentlyBlocked
                  ? Colors.orange
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Text('$action User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to $actionLower this user?',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isCurrentlyBlocked) const SizedBox(height: 12),
            if (!isCurrentlyBlocked)
              Text(
                'Blocked users cannot login or access the platform.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyBlocked
                  ? Colors.orange
                  : Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      controller.blockUser(userId, !isCurrentlyBlocked);
    }
  }
}

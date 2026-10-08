import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/constants/route_constants.dart';
import '../../domain/entities/notification_type.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';

/// Page to display all notifications
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationState.notifications.isNotEmpty &&
              notificationState.unreadCount > 0)
            TextButton.icon(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationProvider.notifier).refresh();
        },
        child: _buildBody(context, ref, notificationState),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    NotificationState state,
  ) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load notifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(notificationProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Icon(
                Icons.notifications_none_rounded,
                size: 80,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No notifications yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ll see notifications here when there\'s something new',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.notifications.length,
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return NotificationCard(
          notification: notification,
          onTap: () async {
            // Mark as read
            if (!notification.isRead) {
              await ref
                  .read(notificationProvider.notifier)
                  .markAsRead(notification.id);
            }

            if (!context.mounted) return;

            // Navigate based on notification type and action URL
            if (notification.actionUrl != null) {
              context.push(notification.actionUrl!);
            } else {
              // Default navigation based on type
              switch (notification.type) {
                case NotificationType.quiz:
                  context.push(RouteConstants.quizList);
                  break;
                case NotificationType.announcement:
                  context.push(RouteConstants.announcements);
                  break;
                case NotificationType.submission:
                  context.push(RouteConstants.quizHistory);
                  break;
                case NotificationType.system:
                  // No default navigation for system notifications
                  break;
              }
            }
          },
          onDismissed: () {
            ref
                .read(notificationProvider.notifier)
                .deleteNotification(notification.id);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Notification deleted'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    // TODO: Implement undo functionality
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

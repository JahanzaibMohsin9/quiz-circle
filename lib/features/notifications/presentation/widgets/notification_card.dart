import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/domain/entities/notification_type.dart';

/// Widget to display a single notification
class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  /// Get icon for notification type
  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.quiz:
        return Icons.quiz_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
      case NotificationType.submission:
        return Icons.assignment_turned_in_rounded;
    }
  }

  /// Get color for notification type
  Color _getColor() {
    switch (notification.type) {
      case NotificationType.quiz:
        return AppColors.primary;
      case NotificationType.announcement:
        return AppColors.accent;
      case NotificationType.system:
        return AppColors.info;
      case NotificationType.submission:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDismissed(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: notification.isRead ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification.isRead
                ? Colors.transparent
                : color.withValues(alpha: 0.2),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Unread indicator
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          // Title
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Message
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Timestamp
                      Text(
                        notification.getRelativeTime(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

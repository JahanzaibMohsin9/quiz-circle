import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../core/constants/animation_constants.dart';

/// Empty state widget for when there's no data to display
class EmptyStateWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionButtonText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionButtonText,
    this.onAction,
  });

  const EmptyStateWidget.quizzes({
    super.key,
    String? message,
    this.onAction,
  }) : title = 'No Quizzes Available',
       message = message ?? 'There are no quizzes assigned to you yet.',
       icon = Icons.quiz_outlined,
       actionButtonText = null;

  const EmptyStateWidget.history({
    super.key,
    String? message,
    this.onAction,
  }) : title = 'No Quiz History',
       message = message ?? 'You haven\'t attempted any quizzes yet.',
       icon = Icons.history_outlined,
       actionButtonText = 'Browse Quizzes';

  const EmptyStateWidget.announcements({
    super.key,
    String? message,
    this.onAction,
  }) : title = 'No Announcements',
       message = message ?? 'There are no announcements at the moment.',
       icon = Icons.notifications_outlined,
       actionButtonText = null;

  const EmptyStateWidget.leaderboard({super.key, String? message})
    : title = 'No Rankings Yet',
      message = message ?? 'No one has completed this quiz yet.',
      icon = Icons.leaderboard_outlined,
      actionButtonText = null,
      onAction = null;

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.durationSlow,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: 50, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.actionButtonText != null &&
                    widget.onAction != null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: widget.onAction,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(widget.actionButtonText!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

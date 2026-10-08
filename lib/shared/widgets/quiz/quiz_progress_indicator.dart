import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';

class QuizProgressIndicator extends StatefulWidget {
  final double progress;
  final int currentQuestion;
  final int totalQuestions;
  final int remainingTimeSeconds;
  final bool isTimerRunning;

  const QuizProgressIndicator({
    super.key,
    required this.progress,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.remainingTimeSeconds,
    this.isTimerRunning = false,
  });

  @override
  State<QuizProgressIndicator> createState() => _QuizProgressIndicatorState();
}

class _QuizProgressIndicatorState extends State<QuizProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _updatePulseAnimation();
  }

  @override
  void didUpdateWidget(QuizProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remainingTimeSeconds != widget.remainingTimeSeconds) {
      _updatePulseAnimation();
    }
  }

  void _updatePulseAnimation() {
    // Pulse when time is running low (< 1 minute)
    if (widget.remainingTimeSeconds <= 60 && widget.remainingTimeSeconds > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = widget.remainingTimeSeconds ~/ 60;
    final seconds = widget.remainingTimeSeconds % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    Color timerColor = AppColors.success;
    IconData timerIcon = Icons.timer_outlined;

    if (widget.remainingTimeSeconds <= 60) {
      timerColor = AppColors.error;
      timerIcon = Icons.timer_off_outlined;
    } else if (widget.remainingTimeSeconds <= 300) {
      // 5 minutes
      timerColor = AppColors.warning;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${widget.currentQuestion} of ${widget.totalQuestions}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                // Timer with pulse animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: timerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: timerColor, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(timerIcon, size: 18, color: timerColor),
                            const SizedBox(width: 6),
                            Text(
                              timeString,
                              style: TextStyle(
                                color: timerColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: widget.progress,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(widget.progress * 100).toInt()}% Complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${widget.totalQuestions - widget.currentQuestion} left',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

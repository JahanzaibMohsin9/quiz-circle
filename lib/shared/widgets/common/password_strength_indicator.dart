import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';

/// Password strength indicator widget
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showLabel;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(context, password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedProgressBar(
                progress: strength.progress,
                gradient: LinearGradient(
                  colors: [
                    strength.color,
                    strength.color.withValues(alpha: 0.6),
                  ],
                ),
                height: 4,
              ),
            ),
          ],
        ),
        if (showLabel && password.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(strength.icon, size: 14, color: strength.color),
              const SizedBox(width: 4),
              Text(
                strength.label,
                style: TextStyle(
                  fontSize: 12,
                  color: strength.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  _PasswordStrength _calculateStrength(BuildContext context, String password) {
    if (password.isEmpty) {
      return _PasswordStrength(
        progress: 0.0,
        label: '',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        icon: Icons.info_outline,
      );
    }

    int score = 0;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Has lowercase
    if (password.contains(RegExp(r'[a-z]'))) score++;

    // Has uppercase
    if (password.contains(RegExp(r'[A-Z]'))) score++;

    // Has numbers
    if (password.contains(RegExp(r'[0-9]'))) score++;

    // Has special characters
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    // Calculate progress and determine strength
    if (score <= 2) {
      return _PasswordStrength(
        progress: 0.25,
        label: 'Weak',
        color: AppColors.error,
        icon: Icons.warning_amber_rounded,
      );
    } else if (score <= 4) {
      return _PasswordStrength(
        progress: 0.5,
        label: 'Fair',
        color: AppColors.warning,
        icon: Icons.info_outline,
      );
    } else if (score <= 5) {
      return _PasswordStrength(
        progress: 0.75,
        label: 'Good',
        color: AppColors.info,
        icon: Icons.check_circle_outline,
      );
    } else {
      return _PasswordStrength(
        progress: 1.0,
        label: 'Strong',
        color: AppColors.success,
        icon: Icons.verified_outlined,
      );
    }
  }
}

class _PasswordStrength {
  final double progress;
  final String label;
  final Color color;
  final IconData icon;

  _PasswordStrength({
    required this.progress,
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// Animated progress bar (moved from animated_counter.dart for reuse)
class AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final double? height;
  final Color? backgroundColor;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.backgroundColor,
    this.gradient,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(100);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.border,
        borderRadius: borderRadius,
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.gradient ?? AppColors.getPrimaryGradient(),
                borderRadius: borderRadius,
              ),
            ),
          );
        },
      ),
    );
  }
}

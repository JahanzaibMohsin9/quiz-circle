import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../core/constants/animation_constants.dart';

/// Shimmer loading widget for skeleton screens
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final ShimmerShape shape;
  final EdgeInsets? margin;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.shape = ShimmerShape.rectangle,
    this.margin,
  });

  const ShimmerLoading.rectangular({
    super.key,
    required this.width,
    required this.height,
    this.margin,
  }) : shape = ShimmerShape.rectangle;

  const ShimmerLoading.circular({super.key, required this.width, this.margin})
    : height = 0,
      shape = ShimmerShape.circle;

  const ShimmerLoading.text({super.key, required this.width, this.margin})
    : height = 16,
      shape = ShimmerShape.text;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.shimmer,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.shimmerBaseDark
        : AppColors.shimmerBase;
    final highlightColor = isDark
        ? AppColors.shimmerHighlightDark
        : AppColors.shimmerHighlight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.shape == ShimmerShape.circle
              ? widget.width
              : widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: _getBorderRadius(),
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }

  BorderRadius? _getBorderRadius() {
    switch (widget.shape) {
      case ShimmerShape.circle:
        return BorderRadius.circular(widget.width / 2);
      case ShimmerShape.text:
        return BorderRadius.circular(4);
      case ShimmerShape.rectangle:
        return BorderRadius.circular(8);
    }
  }
}

enum ShimmerShape { rectangle, circle, text }

/// Shimmer loading for quiz card
class ShimmerQuizCard extends StatelessWidget {
  const ShimmerQuizCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading.text(
                        width: 200,
                        margin: EdgeInsets.only(bottom: 8),
                      ),
                      ShimmerLoading.text(width: 150),
                    ],
                  ),
                ),
                ShimmerLoading.rectangular(
                  width: 60,
                  height: 24,
                  margin: EdgeInsets.only(left: 8),
                ),
              ],
            ),
            SizedBox(height: 12),
            ShimmerLoading.text(width: 100),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading for list items
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ShimmerLoading.circular(
            width: 48,
            margin: EdgeInsets.only(right: 12),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading.text(
                  width: 150,
                  margin: EdgeInsets.only(bottom: 4),
                ),
                ShimmerLoading.text(
                  width: 100,
                  margin: EdgeInsets.only(top: 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

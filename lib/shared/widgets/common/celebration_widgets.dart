import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import 'dart:math' as math;

/// Confetti celebration widget
class ConfettiWidget extends StatefulWidget {
  final bool isActive;
  final Duration duration;

  const ConfettiWidget({
    super.key,
    this.isActive = false,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _initializeParticles();

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && !_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  void _initializeParticles() {
    _particles.clear();
    const particleCount = 50;

    for (int i = 0; i < particleCount; i++) {
      _particles.add(
        ConfettiParticle(
          color: _getRandomColor(),
          startX: _random.nextDouble(),
          velocityX: (_random.nextDouble() - 0.5) * 2,
          velocityY: -(_random.nextDouble() * 2 + 1),
          rotation: _random.nextDouble() * 2 * math.pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 4,
        ),
      );
    }
  }

  Color _getRandomColor() {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.gold,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        painter: ConfettiPainter(
          particles: _particles,
          progress: _controller.value,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class ConfettiParticle {
  final Color color;
  final double startX;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.color,
    required this.startX,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      // Calculate position with gravity
      final x =
          size.width * particle.startX +
          particle.velocityX * size.width * progress;
      final y =
          size.height * 0.2 +
          particle.velocityY * size.height * progress +
          0.5 * 9.8 * 20 * progress * progress; // Gravity effect

      // Calculate rotation
      final rotation =
          particle.rotation + particle.rotationSpeed * progress * 2 * math.pi;

      // Don't draw particles that have fallen off screen
      if (y > size.height) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Draw confetti piece (rectangle)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -8, 8, 16),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// Success checkmark animation
class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const AnimatedCheckmark({
    super.key,
    this.size = 100,
    this.color = AppColors.success,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: CheckmarkPainter(
              color: widget.color,
              progress: _checkAnimation.value,
            ),
          ),
        );
      },
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final Color color;
  final double progress;

  CheckmarkPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw circle background
    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      circlePaint,
    );

    // Draw checkmark
    final path = Path();

    final p1 = Offset(size.width * 0.25, size.height * 0.5);
    final p2 = Offset(size.width * 0.45, size.height * 0.7);
    final p3 = Offset(size.width * 0.75, size.height * 0.35);

    path.moveTo(p1.dx, p1.dy);

    if (progress < 0.5) {
      // First segment (to middle point)
      final t = progress * 2;
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      // First segment complete
      path.lineTo(p2.dx, p2.dy);

      // Second segment (from middle to end)
      final t = (progress - 0.5) * 2;
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

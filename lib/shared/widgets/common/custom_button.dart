import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../core/constants/animation_constants.dart';
import '../../../core/utils/accessibility_helper.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool isLoading;
  final IconData? icon;
  final bool iconRight;
  final Gradient? gradient;
  final double? width;
  final EdgeInsets? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.outlined = false,
    this.isLoading = false,
    this.icon,
    this.iconRight = false,
    this.gradient,
    this.width,
    this.padding,
  });

  const CustomButton.gradient({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.iconRight = false,
    this.width,
    this.padding,
  }) : outlined = false,
       gradient = const LinearGradient(
         colors: AppColors.primaryGradient,
         begin: Alignment.topLeft,
         end: Alignment.bottomRight,
       );

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.buttonPress,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AnimationConstants.buttonPressScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return Semantics(
      button: true,
      label: AccessibilityHelper.buttonLabel(
        widget.text,
        isDisabled: isDisabled,
      ),
      enabled: !isDisabled,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: SizedBox(
            width: widget.width,
            child: widget.outlined
                ? _buildOutlinedButton(isDisabled)
                : _buildElevatedButton(isDisabled),
          ),
        ),
      ),
    );
  }

  Widget _buildElevatedButton(bool isDisabled) {
    if (widget.gradient != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: isDisabled ? null : widget.gradient,
          color: isDisabled ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.5) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElevatedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _buildButtonContent(),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isDisabled ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        padding:
            widget.padding ??
            const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildOutlinedButton(bool isDisabled) {
    return OutlinedButton(
      onPressed: isDisabled ? null : widget.onPressed,
      style: OutlinedButton.styleFrom(
        padding:
            widget.padding ??
            const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.outlined ? AppColors.primary : Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(widget.text),
        ],
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.iconRight
            ? [
                Text(widget.text),
                const SizedBox(width: 8),
                Icon(widget.icon, size: 20),
              ]
            : [
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
                Text(widget.text),
              ],
      );
    }

    return Text(widget.text);
  }
}

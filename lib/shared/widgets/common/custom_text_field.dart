import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/colors.dart';
import '../../../core/constants/animation_constants.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final bool showClearButton;
  final int? maxLength;
  final int? maxLines;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.showClearButton = false,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _borderAnimation;
  bool _hasText = false;
  bool _obscureTextToggle = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureTextToggle = widget.obscureText;
    _hasText = widget.controller.text.isNotEmpty;

    _animationController = AnimationController(
      vsync: this,
      duration: AnimationConstants.durationFast,
    );

    _borderAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() {});
  }

  void _onTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(widget.controller.text);
  }

  void _clearText() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  void _toggleObscureText() {
    setState(() {
      _obscureTextToggle = !_obscureTextToggle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _borderAnimation,
      builder: (context, child) {
        return TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          obscureText: _obscureTextToggle,
          enabled: widget.enabled,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _focusNode.hasFocus
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : null,
            suffixIcon: _buildSuffixIcon(),
            counterText: widget.maxLength != null ? null : '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: _borderAnimation.value,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: widget.validator,
        );
      },
    );
  }

  Widget? _buildSuffixIcon() {
    final List<Widget> icons = [];

    // Password toggle icon
    if (widget.obscureText) {
      icons.add(
        IconButton(
          icon: Icon(
            _obscureTextToggle ? Icons.visibility_off : Icons.visibility,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: _toggleObscureText,
          tooltip: _obscureTextToggle ? 'Show password' : 'Hide password',
        ),
      );
    }

    // Custom suffix icon
    if (widget.suffixIcon != null) {
      icons.add(
        IconButton(
          icon: Icon(
            widget.suffixIcon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: widget.onSuffixIconTap,
        ),
      );
    }

    // Clear button
    if (widget.showClearButton && _hasText && !widget.obscureText) {
      icons.add(
        IconButton(
          icon: Icon(
            Icons.clear,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: _clearText,
          tooltip: 'Clear',
        ),
      );
    }

    if (icons.isEmpty) return null;
    if (icons.length == 1) return icons.first;

    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }
}

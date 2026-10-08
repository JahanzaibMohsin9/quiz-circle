import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../core/constants/animation_constants.dart';

/// Error state widget with retry functionality
class ErrorStateWidget extends StatefulWidget {
  final String message;
  final ErrorType errorType;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.errorType = ErrorType.generic,
    this.onRetry,
    this.retryButtonText,
  });

  const ErrorStateWidget.network({
    super.key,
    String? message,
    this.onRetry,
    this.retryButtonText,
  }) : message = message ?? 'No internet connection',
       errorType = ErrorType.network;

  const ErrorStateWidget.server({
    super.key,
    String? message,
    this.onRetry,
    this.retryButtonText,
  }) : message = message ?? 'Server error occurred',
       errorType = ErrorType.server;

  const ErrorStateWidget.notFound({super.key, String? message, this.onRetry})
    : message = message ?? 'Content not found',
      errorType = ErrorType.notFound,
      retryButtonText = null;

  @override
  State<ErrorStateWidget> createState() => _ErrorStateWidgetState();
}

class _ErrorStateWidgetState extends State<ErrorStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.durationMedium,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

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
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildErrorIcon(),
                const SizedBox(height: 24),
                Text(
                  _getErrorTitle(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isRetrying ? null : _handleRetry,
                    icon: _isRetrying
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.refresh,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    label: Text(
                      _isRetrying
                          ? 'Retrying...'
                          : widget.retryButtonText ?? 'Try Again',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    IconData iconData;
    Color iconColor;

    switch (widget.errorType) {
      case ErrorType.network:
        iconData = Icons.wifi_off_rounded;
        iconColor = AppColors.warning;
        break;
      case ErrorType.server:
        iconData = Icons.cloud_off_rounded;
        iconColor = AppColors.error;
        break;
      case ErrorType.notFound:
        iconData = Icons.search_off_rounded;
        iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
        break;
      case ErrorType.generic:
        iconData = Icons.error_outline_rounded;
        iconColor = AppColors.error;
        break;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 40, color: iconColor),
    );
  }

  String _getErrorTitle() {
    switch (widget.errorType) {
      case ErrorType.network:
        return 'No Connection';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.notFound:
        return 'Not Found';
      case ErrorType.generic:
        return 'Oops! Something went wrong';
    }
  }

  Future<void> _handleRetry() async {
    setState(() => _isRetrying = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onRetry?.call();
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }
}

enum ErrorType { generic, network, server, notFound }

import 'package:flutter/material.dart';

class ErrorTextWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorTextWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: const TextStyle(color: Colors.red)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';

class AnswerOption extends StatelessWidget {
  final String text;
  final String value;
  final String? selectedValue;
  final bool isCorrect;
  final bool isEnabled;
  final ValueChanged<String?> onChanged;

  const AnswerOption({
    super.key,
    required this.text,
    required this.value,
    this.selectedValue,
    this.isCorrect = false,
    this.isEnabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? () => onChanged(value) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _getBorderColor(context, isSelected),
                width: isSelected ? 2.5 : 2, // Thicker border when selected
              ),
              borderRadius: BorderRadius.circular(12),
              color: _getBackgroundColor(context, isSelected),
              // Add glow effect for selected option in dark mode
              boxShadow: isSelected && isEnabled
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: isDark ? 0.4 : 0.2),
                        blurRadius: isDark ? 12 : 8,
                        spreadRadius: isDark ? 2 : 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getBorderColor(context, isSelected),
                      width: 2,
                    ),
                    color: _getRadioColor(context, isSelected),
                  ),
                  child: Center(
                    child: isSelected
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: !isEnabled
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5)
                          : (isSelected
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                // Show checkmark during quiz (isEnabled = true) when selected
                // Show check/cancel icons after submission (isEnabled = false)
                if (isSelected)
                  Icon(
                    !isEnabled
                        ? (isCorrect ? Icons.check_circle : Icons.cancel)
                        : Icons.check_circle_outline,
                    color: !isEnabled
                        ? (isCorrect
                              ? AppColors.quizCorrect
                              : AppColors.quizIncorrect)
                        : Theme.of(context).primaryColor,
                    size: 24,
                  )
                else
                  const SizedBox(width: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(BuildContext context, bool isSelected) {
    // During quiz (isEnabled = true), use neutral colors
    // After submission (isEnabled = false), show correct/incorrect colors
    if (isEnabled) {
      // Quiz in progress - neutral colors only
      if (isSelected) {
        return Theme.of(context).primaryColor;
      }
      return Theme.of(context).primaryColor.withValues(alpha: 0.5);
    }

    // Quiz submitted - show results with correct/incorrect colors
    if (isSelected) {
      return isCorrect ? AppColors.quizCorrect : AppColors.quizIncorrect;
    }
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
  }

  Color _getBackgroundColor(BuildContext context, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // During quiz (isEnabled = true), use neutral colors
    // After submission (isEnabled = false), show correct/incorrect colors
    if (isEnabled) {
      // Quiz in progress - neutral colors only, stronger in dark mode
      return isSelected
          ? Theme.of(context).primaryColor.withValues(
              alpha: isDark ? 0.25 : 0.1, // Higher opacity in dark mode
            )
          : Colors.transparent;
    }

    // Quiz submitted - show results with correct/incorrect colors
    if (isSelected) {
      if (isCorrect) {
        return AppColors.quizCorrect.withValues(alpha: isDark ? 0.2 : 0.1);
      } else {
        return AppColors.quizIncorrect.withValues(alpha: isDark ? 0.2 : 0.1);
      }
    }
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1);
  }

  Color _getRadioColor(BuildContext context, bool isSelected) {
    if (!isSelected) return Colors.transparent;

    // During quiz (isEnabled = true), use primary color
    // After submission (isEnabled = false), show correct/incorrect colors
    if (isEnabled) {
      return Theme.of(context).primaryColor;
    }
    return isCorrect ? AppColors.quizCorrect : AppColors.quizIncorrect;
  }
}

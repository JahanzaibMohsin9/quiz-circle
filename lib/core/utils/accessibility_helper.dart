import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility helper for improved app accessibility
class AccessibilityHelper {
  AccessibilityHelper._();

  /// Generate semantic label for buttons
  static String buttonLabel(String text, {bool isDisabled = false}) {
    return isDisabled ? '$text, disabled' : text;
  }

  /// Generate semantic label for timer
  static String timerLabel(int minutes, int seconds) {
    return '$minutes minutes and $seconds seconds remaining';
  }

  /// Generate semantic label for score
  static String scoreLabel(int score, int total) {
    return 'Score: $score out of $total';
  }

  /// Generate semantic label for quiz card
  static String quizCardLabel({
    required String title,
    required int duration,
    required bool isActive,
  }) {
    final status = isActive ? 'active' : 'inactive';
    return '$title, Duration: $duration minutes, Status: $status';
  }

  /// Generate semantic label for leaderboard rank
  static String leaderboardRankLabel({
    required int rank,
    required String name,
    required int score,
  }) {
    String position;
    if (rank == 1) {
      position = '1st place';
    } else if (rank == 2) {
      position = '2nd place';
    } else if (rank == 3) {
      position = '3rd place';
    } else {
      position = '${rank}th place';
    }
    return '$position: $name with $score points';
  }

  /// Generate semantic label for question number
  static String questionNumberLabel(int current, int total) {
    return 'Question $current of $total';
  }

  /// Announce to screen reader
  static void announce(BuildContext context, String message) {
    final view = View.of(context);
    SemanticsService.sendAnnouncement(view, message, TextDirection.ltr);
  }

  /// Check if high contrast is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Check if bold text is enabled
  static bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// Get text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  /// Check if reduce motion is enabled
  static bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Wrap widget with semantic label
  static Widget withSemantics({
    required Widget child,
    required String label,
    String? hint,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }

  /// Create focus node with accessibility support
  static FocusNode createFocusNode({String? debugLabel}) {
    return FocusNode(debugLabel: debugLabel);
  }
}

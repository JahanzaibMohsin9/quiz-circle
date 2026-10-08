import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ========== Brand Colors (Premium Gold) ==========
  // Primary: Muted Gold / Brass - Luxury, Trust, Premium
  static const Color primary = Color(0xFFC6A87C); // Muted Gold
  static const Color primaryVariant = Color(0xFFB08D55); // Darker Gold
  static const Color primaryLight = Color(0xFFE0C097); // Lighter Gold
  static const Color primaryDark = Color(0xFF8C6B3D); // Deep Gold/Bronze
  static const Color onPrimary = Color(0xFFFFFFFF); // White text on gold

  // Secondary: Deep Charcoal - Professional, Modern
  static const Color secondary = Color(0xFF2A2D35); // Accent Charcoal
  static const Color secondaryVariant = Color(0xFF1F2228); // Darker
  static const Color secondaryLight = Color(0xFF40444F); // Lighter
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Accent: Subtle Brass/Metallic
  static const Color accent = Color(0xFFD4AF37); // Metallic Gold
  static const Color accentLight = Color(0xFFF4D06F);
  static const Color accentDark = Color(0xFFA68222);
  static const Color onAccent = Color(0xFF000000);

  // ========== Surface Colors (Light Theme - Adapted for Premium Light) ==========
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF9FAFB); // Very light grey
  static const Color background = Color(0xFFF3F4F6); // Light grey
  static const Color onSurface = Color(0xFF111827); // Near black
  static const Color onSurfaceVariant = Color(0xFF4B5563); // Grey-600
  static const Color outline = Color(0xFFE5E7EB); // Grey-200
  static const Color outlineVariant = Color(0xFFF3F4F6);

  // ========== Surface Colors (Dark Theme - Premium Charcoal) ==========
  // Deep charcoal/black foundation
  static const Color darkBackground = Color(0xFF121212); // Near Black
  static const Color darkSurface = Color(0xFF1E1E1E); // Card Surface
  static const Color darkSurfaceVariant = Color(0xFF252525); // Slightly lighter
  static const Color darkOnSurface = Color(
    0xFFFFFFFF,
  ); // Pure White for better contrast
  static const Color darkOnSurfaceVariant = Color(
    0xFFCACACA,
  ); // Light Grey // Neutral Grey
  static const Color darkOutline = Color(0xFF333333); // Subtle border
  static const Color darkOutlineVariant = Color(0xFF2A2A2A); // Even subtler

  // ========== Status Colors (Refined for Premium) ==========
  // Error - Muted Red
  static const Color error = Color(0xFFCF6679);
  static const Color errorContainer = Color(0xFFB00020);
  static const Color onErrorContainer = Colors.white;
  static const Color darkErrorContainer = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);

  // Success - Muted Emerald
  static const Color success = Color(0xFF4ADE80); // Softer Green
  static const Color successContainer = Color(0xFF065F46);
  static const Color onSuccessContainer = Colors.white;
  static const Color darkSuccessContainer = Color(0xFF064E3B);
  static const Color darkOnSuccessContainer = Color(0xFFA7F3D0);

  // Warning - Amber Gold
  static const Color warning = Color(0xFFFBBC05);
  static const Color warningContainer = Color(0xFF7C5E10);
  static const Color onWarningContainer = Colors.white;
  static const Color darkWarningContainer = Color(0xFF451B00); // Deep Amber
  static const Color darkOnWarningContainer = Color(0xFFFFDCC2);

  // Info - Muted Blue
  static const Color info = Color(0xFF60A5FA);
  static const Color infoContainer = Color(0xFF1E3A8A);
  static const Color onInfoContainer = Colors.white;
  static const Color darkInfoContainer = Color(0xFF0B254E); // Deep Blue
  static const Color darkOnInfoContainer = Color(0xFFD1E4FF);

  // ========== Quiz Specific Colors ==========
  static const Color quizCorrect = Color(0xFF4ADE80);
  static const Color quizIncorrect = Color(0xFFEF4444);
  static const Color quizNeutral = Color(0xFF6B7280);
  static const Color quizSelected = Color(0xFFC6A87C); // Gold
  static const Color quizUnanswered = Color(0xFF525252);

  // ========== Gradients (Premium) ==========
  static const List<Color> primaryGradient = [
    Color(0xFFC6A87C), // Muted Gold
    Color(0xFFB08D55), // Darker Gold
  ];

  static const List<Color> darkPrimaryGradient = [
    Color(0xFF1E1E1E), // Dark Surface
    Color(0xFF2A2A2A), // Slightly lighter
  ];

  // Gold Gradient for specific highlights
  static const List<Color> goldGradient = [
    Color(0xFFD4AF37),
    Color(0xFFC5A065),
  ];

  // ========== Legacy Compatibility ==========
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color darkTextPrimary = darkOnSurface;
  static const Color darkTextSecondary = darkOnSurfaceVariant;

  static const Color border = outlineVariant;
  static const Color darkBorder = darkOutlineVariant;

  // ========== Leaderboard Colors ==========
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // ========== Additional Gradients ==========
  static const List<Color> successGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  static const List<Color> errorGradient = [
    Color(0xFFEF4444),
    Color(0xFFDC2626),
  ];

  // ========== Shimmer Colors ==========
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF2A2A2A);
  static const Color shimmerHighlightDark = Color(0xFF333333);

  // ========== Text Colors ==========
  static const Color textTertiary = Color(0xFF6B7280);

  // ========== Helpers ==========
  static LinearGradient getPrimaryGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    bool isDark = false,
  }) {
    return LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF252525), // Dark Grey
              const Color(0xFF121212), // Deep Black
            ]
          : primaryGradient,
      begin: begin,
      end: end,
    );
  }
}

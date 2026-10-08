import 'package:flutter/animation.dart';

/// Animation constants for consistent timing and curves across the app
class AnimationConstants {
  AnimationConstants._();

  // Duration constants
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVerySlow = Duration(milliseconds: 800);

  // Specific animation durations
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration buttonPress = Duration(milliseconds: 150);
  static const Duration cardReveal = Duration(milliseconds: 400);
  static const Duration shimmer = Duration(milliseconds: 1500);
  static const Duration counterAnimation = Duration(milliseconds: 800);
  static const Duration errorShake = Duration(milliseconds: 400);

  // Animation curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceIn = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve decelerate = Curves.decelerate;

  // Scale values for button press
  static const double buttonPressScale = 0.95;
  static const double cardPressScale = 0.98;

  // Opacity values
  static const double disabledOpacity = 0.5;
  static const double hoverOpacity = 0.08;
  static const double pressedOpacity = 0.12;

  // Stagger delays for list animations
  static const Duration staggerDelay = Duration(milliseconds: 50);
  static const Duration staggerDelayLong = Duration(milliseconds: 100);
}

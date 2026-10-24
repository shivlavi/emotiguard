import 'package:flutter/material.dart';

class AppColors {
  // Primary Calm Tones (Gentle Greens & Soft Blues)
  static const Color primaryTeal = Color(0xFF2C7A7B);       // Grounding teal
  static const Color primaryLight = Color(0xFF4FD1C5);      // Soft aqua
  static const Color sageGreen = Color(0xFF38A169);         // Restorative sage
  static const Color softLavender = Color(0xFF805AD5);      // Calming violet
  static const Color skyBlue = Color(0xFF3182CE);           // Serene blue

  // Soft Distress Indicators (Gentle, non-alarmist palette)
  // Replaces harsh neon red with soft terra cotta / muted coral
  static const Color statusCalm = Color(0xFF38A169);        // Calm & balanced (Sage)
  static const Color statusMild = Color(0xFF319795);        // Gentle tension (Teal)
  static const Color statusElevated = Color(0xFFDD6B20);    // Moderate arousal (Warm ochre)
  static const Color statusHigh = Color(0xFFC53030);        // Deep muted brick/rose (Soft, non-flashing)

  // Surface & Background (Light)
  static const Color bgLight = Color(0xFFF7FAFC);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textLightPrimary = Color(0xFF1A202C);
  static const Color textLightSecondary = Color(0xFF718096);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Surface & Background (Dark)
  static const Color bgDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color cardDarkElevated = Color(0xFF334155);
  static const Color textDarkPrimary = Color(0xFFF1F5F9);
  static const Color textDarkSecondary = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  // Metric Specific Accents
  static const Color heartRate = Color(0xFFE53E3E);     // Pulse accent (contained)
  static const Color hrvParasympathetic = Color(0xFF319795); // Deep Teal
  static const Color edaArousal = Color(0xFFD69E2E);    // Warm Gold/Amber
  static const Color movementAccel = Color(0xFF4299E1); // Breeze Blue
}

import 'package:flutter/material.dart';

/// Single source of truth for all application colors.
/// Naming convention: c + hex value (e.g. c987656 = #987656).
abstract final class AppColors {
  // Brand / military palette
  static const Color c000000 = Color(0xFF000000);
  static const Color cFFFFFF = Color(0xFFFFFFFF);
  static const Color cA51D21 = Color(0xFFA51D21); // Army red
  static const Color c2F0A8C = Color(0xFF2F0A8C); // Navy blue
  static const Color c75AADB = Color(0xFF75AADB); // Air force blue
  static const Color cF4B400 = Color(0xFFF4B400); // Gold
  static const Color c1B3A2F = Color(0xFF1B3A2F); // Deep military green
  static const Color c2C3E50 = Color(0xFF2C3E50); // Slate navy
  static const Color cF5F6F8 = Color(0xFFF5F6F8); // Muted surface
  static const Color cE8EAED = Color(0xFFE8EAED); // Border
  static const Color c6B7280 = Color(0xFF6B7280); // Muted text
  static const Color c374151 = Color(0xFF374151); // Body text
  static const Color cDC2626 = Color(0xFFDC2626); // Error / violation
  static const Color cF59E0B = Color(0xFFF59E0B); // Warning
  static const Color c16A34A = Color(0xFF16A34A); // Success

  // Semantic aliases
  static const Color primary = c1B3A2F;
  static const Color secondary = c2C3E50;
  static const Color accent = cF4B400;
  static const Color background = cFFFFFF;
  static const Color surface = cFFFFFF;
  static const Color border = cE8EAED;
  static const Color textPrimary = c374151;
  static const Color textSecondary = c6B7280;
  static const Color error = cDC2626;
  static const Color warning = cF59E0B;
  static const Color success = c16A34A;
  static const Color splashBackground = cFFFFFF;
}

import 'package:flutter/material.dart';

/// Single source of truth for all application colors.
/// Naming convention: c + hex value (e.g. c987656 = #987656).
abstract final class AppColors {
  // Brand / military palette
  static const Color c000000 = Color(0xFF000000);
  static const Color cFFFFFF = Color(0xFFFFFFFF);
  static const Color cFCFFFE = Color(0xFFFCFFFE); // Near-white background
  static const Color cA51D21 = Color(0xFFA51D21); // Army red
  static const Color c2F0A8C = Color(0xFF2F0A8C); // Navy blue
  static const Color c75AADB = Color(0xFF75AADB); // Air force blue
  static const Color cF4B400 = Color(0xFFF4B400); // Gold
  static const Color c1B3A2F = Color(0xFF1B3A2F); // Deep military green
  static const Color c0A5943 = Color(0xFF0A5943); // Primary green
  static const Color c094C3C = Color(0xFF094C3C); // Dark green (headings)
  static const Color c176B4D = Color(0xFF176B4D); // Medium green (active dot)
  static const Color c89D5B2 = Color(0xFF89D5B2); // Light green (icon bg / shadow)
  static const Color c2C3E50 = Color(0xFF2C3E50); // Slate navy
  static const Color cF5F6F8 = Color(0xFFF5F6F8); // Muted surface
  static const Color cE8EAED = Color(0xFFE8EAED); // Border
  static const Color cD9E5DE = Color(0xFFD9E5DE); // Inactive dot
  static const Color c474E5A = Color(0xFF474E5A); // Description text
  static const Color c6B7280 = Color(0xFF6B7280); // Muted text
  static const Color c374151 = Color(0xFF374151); // Body text
  static const Color cDC2626 = Color(0xFFDC2626); // Error / violation
  static const Color cF59E0B = Color(0xFFF59E0B); // Warning
  static const Color c16A34A = Color(0xFF16A34A); // Success
  static const Color c1D8A57 = Color(0xFF1D8A57); // Checklist badge
  static const Color cEAF4EF = Color(0xFFEAF4EF); // Checklist row bg
  static const Color c0F3D2E = Color(0xFF0F3D2E); // Checklist label / gradient start
  static const Color c23966A = Color(0xFF23966A); // Gradient end (login header)
  static const Color c17231D = Color(0xFF17231D); // Field label text
  static const Color c66736C = Color(0xFF66736C); // Login description text
  static const Color cBDBDBD = Color(0xFFBDBDBD); // Outlined button border
  static const Color c4ADE80 = Color(0xFF4ADE80); // Progress bar fill
  static const Color cE5EBE7 = Color(0xFFE5EBE7); // Disabled button bg
  static const Color cF7FAF8 = Color(0xFFF7FAF8); // Nav bar bg
  static const Color c98A39D = Color(0xFF98A39D); // Disabled button text
  static const Color cF9F9F9 = Color(0xFFF9F9F9); // Gallery banned bg
  static const Color cF0F4F2 = Color(0xFFF0F4F2); // Image preview area
  static const Color cFEF2F2 = Color(0xFFFEF2F2); // Delete button bg / violation bg
  static const Color cFEE2E2 = Color(0xFFFEE2E2); // Violation alert / icon glow
  static const Color cF5C6CC = Color(0xFFF5C6CC); // Delete button border
  static const Color cC43D4D = Color(0xFFC43D4D); // Delete button text / violation
  static const Color cCE5D6A = Color(0xFFCE5D6A); // Violation shield icon
  static const Color c9A9A9A = Color(0xFF9A9A9A); // Action bar border

  // Semantic aliases
  static const Color primary = c0A5943;
  static const Color secondary = c2C3E50;
  static const Color accent = cF4B400;
  static const Color background = cFCFFFE;
  static const Color surface = cFFFFFF;
  static const Color border = cE8EAED;
  static const Color textPrimary = c374151;
  static const Color textSecondary = c6B7280;
  static const Color error = cDC2626;
  static const Color warning = cF59E0B;
  static const Color success = c16A34A;
  static const Color splashBackground = cFFFFFF;
  static const Color instructionDotActive = c176B4D;
  static const Color instructionDotInactive = cD9E5DE;
}

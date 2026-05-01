import 'package:flutter/material.dart';

class AppColors {
  // ── Dark palette ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0D0D12);
  static const Color surface = Color(0xFF16161F);
  static const Color surfaceElevated = Color(0xFF1E1E2E);
  static const Color primary = Color(0xFF7C6FF7);
  static const Color primaryGlow = Color(0x407C6FF7);
  static const Color secondary = Color(0xFF4ECDC4);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFD93D);
  static const Color textPrimary = Color(0xFFF0F0F8);
  static const Color textSecondary = Color(0xFF8A8AA0);
  static const Color textMuted = Color(0xFF4A4A60);
  static const Color borderSubtle = Color(0x0FFFFFFF);

  // ── Light palette ─────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceElevated = Color(0xFFF0F0F2);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF5A5A70);
  static const Color lightTextMuted = Color(0xFF9A9AB0);
  static const Color lightBorderSubtle = Color(0x1A000000);

  /// Returns the color appropriate for the current theme brightness.
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? background
          : lightBackground;

  static Color sf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surface : lightSurface;

  static Color sfElevated(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceElevated
          : lightSurfaceElevated;

  static Color txt(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimary
          : lightTextPrimary;

  static Color txtSec(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondary
          : lightTextSecondary;

  static Color txtMut(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textMuted
          : lightTextMuted;

  static Color bdr(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? borderSubtle
          : lightBorderSubtle;
}

/// Convenience extension to access all theme-aware colors from any
/// [BuildContext] via a single getter.
extension AppColorsExtension on BuildContext {
  AppColors get colors => AppColors();
}


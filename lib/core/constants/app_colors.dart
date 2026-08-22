import 'package:flutter/material.dart';

/// Centralized Color Tokens and Design Constants for One Smart Era
class AppColors {
  // Brand Primary & Secondary Palette
  static const Color primary = Color(0xFF10B981); // Vibrant Emerald
  static const Color primaryDark = Color(0xFF0F766E); // Deep Forest Teal
  static const Color primaryLight = Color(0xFF34D399); // Light Mint
  
  static const Color secondary = Color(0xFF0EA5E9); // Ocean Cyan
  static const Color secondaryDark = Color(0xFF0284C7);
  
  static const Color accent = Color(0xFFF59E0B); // Amber Gold
  static const Color accentOrange = Color(0xFFF97316); // Solar Orange
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444); // Crimson Red (SOS)
  static const Color info = Color(0xFF3B82F6);
  static const Color pending = Color(0xFFF59E0B);
  static const Color assigned = Color(0xFF3B82F6);
  static const Color inProgress = Color(0xFF8B5CF6);
  static const Color resolved = Color(0xFF10B981);

  // Background & Surface
  static const Color bgDark = Color(0xFF0A1118); // Ultra dark slate
  static const Color bgDarkCard = Color(0xFF13202D);
  static const Color bgMesh1 = Color(0xFF0D2538);
  static const Color bgMesh2 = Color(0xFF0A3622);
  static const Color bgMesh3 = Color(0xFF2E1C0C);

  // Glassmorphic Surface Colors
  static Color glassBg = Colors.white.withValues(alpha: 0.08);
  static Color glassBorder = Colors.white.withValues(alpha: 0.15);
  static Color glassHighlight = Colors.white.withValues(alpha: 0.25);
  static Color glassDarkBg = const Color(0xFF0F172A).withValues(alpha: 0.65);
  static Color glassDarkBorder = Colors.white.withValues(alpha: 0.12);

  // High-Contrast Text Colors for Maximum Visibility
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure Crisp White
  static const Color textSecondary = Color(0xFFE2E8F0); // Bright High-Contrast Slate
  static const Color textMuted = Color(0xFFCBD5E1); // Readable Muted Text
  static const Color textDark = Color(0xFF0F172A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0x1FFFFFFF), Color(0x0AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

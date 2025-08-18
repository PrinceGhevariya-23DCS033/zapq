import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6B73FF);
  static const Color primaryDark = Color(0xFF5A63E8);
  static const Color primaryLight = Color(0xFF8B93FF);

  // Secondary Colors
  static const Color secondary = Color(0xFF00D4AA);
  static const Color secondaryDark = Color(0xFF00B894);
  static const Color secondaryLight = Color(0xFF33DDB8);

  // Accent Colors
  static const Color accent = Color(0xFFFF6B9D);
  static const Color accentLight = Color(0xFFFF8BB5);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F4);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);

  // Status Colors
  static const Color success = Color(0xFF48BB78);
  static const Color warning = Color(0xFFED8936);
  static const Color error = Color(0xFFF56565);
  static const Color info = Color(0xFF4299E1);

  // Queue Status Colors
  static const Color queueActive = Color(0xFF48BB78);
  static const Color queueWaiting = Color(0xFFED8936);
  static const Color queueCompleted = Color(0xFF4299E1);
  static const Color queueCancelled = Color(0xFFF56565);

  // Map Colors
  static const Color mapPrimary = Color(0xFF6B73FF);
  static const Color mapSelected = Color(0xFFFF6B9D);
  static const Color mapUnselected = Color(0xFF718096);

  // Other Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF2F7);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
}

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.secondaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accent, AppColors.accentLight],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.background, AppColors.surface],
  );
}

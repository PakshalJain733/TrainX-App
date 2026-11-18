// ─── App Colors & Theme matching TrainX Web UI ───────────────────────────────
import 'package:flutter/material.dart';

class TrainXColors {
  // Primary brand (TrainX Royal Blue from CSS: #0052cc / #0053c0)
  static const Color primary = Color(0xFF0053C0);
  static const Color primaryDark = Color(0xFF0F2942);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color primaryBorder = Color(0xFF93C5FD);

  // Sidebar bg (#dbe6f2)
  static const Color sidebarBg = Color(0xFFDBE6F2);
  static const Color sidebarText = Color(0xFF64748B);
  static const Color sidebarTextBright = Color(0xFF0F172A);

  // General backgrounds
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDashed = Color(0xFFCBD5E1);

  // Text shades
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Hero card gradient (exact from .overview-hero-card-student in ST_Overview.css)
  static const Color heroGrad1 = Color(0xFF0F2942);
  static const Color heroGrad2 = Color(0xFF0053C0);

  // Stat card accent colors
  static const Color amber = Color(0xFFF59E0B);
  static const Color teal = Color(0xFF0D9488);
  static const Color orange = Color(0xFFF97316);
  static const Color emerald = Color(0xFF10B981);

  // Leaderboard medal colours
  static const Color gold = Color(0xFFF59E0B);
  static const Color silver = Color(0xFF94A3B8);
  static const Color bronze = Color(0xFFF97316);
}

class TrainXTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: TrainXColors.primary,
          primary: TrainXColors.primary,
          surface: TrainXColors.pageBg,
        ),
        scaffoldBackgroundColor: TrainXColors.pageBg,
        cardTheme: const CardThemeData(
          color: TrainXColors.cardBg,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: TrainXColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
      );
}

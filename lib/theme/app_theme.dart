import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens and theme system derived from 'Finance Tracker UI Redesign' (Stitch).
class AppTheme {
  AppTheme._();

  // --- Surfaces & Canvas ---
  static const Color canvasBackground = Color(0xFFF8FAFC); // Slate-50 base
  static const Color surfaceCard = Color(0xFFFFFFFF);     // Pure white container
  static const Color surfaceMuted = Color(0xFFF1F5F9);    // Slate-100

  // --- Neutrals (Slate scale) ---
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  // --- Semantic: Inflow / Income (Emerald) ---
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald950 = Color(0xFF022C22);

  // --- Semantic: Outflow / Expense (Rose / Red) ---
  static const Color rose50 = Color(0xFFFEF2F2);
  static const Color rose100 = Color(0xFFFEE2E2);
  static const Color rose200 = Color(0xFFFECDD3);
  static const Color rose400 = Color(0xFFFB7185);
  static const Color rose500 = Color(0xFFEF4444);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color rose700 = Color(0xFFBE123C);

  // --- Gradients ---
  static const LinearGradient heroWalletGradient = LinearGradient(
    colors: [
      Color(0xFF0F172A), // Slate-900
      Color(0xFF1E293B), // Slate-800
      Color(0xFF064E3B), // Emerald-900
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Shadows ---
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> heroCardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.18),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static final List<BoxShadow> floatingShadowEmerald = [
    BoxShadow(
      color: emerald600.withOpacity(0.32),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> floatingShadowRose = [
    BoxShadow(
      color: rose600.withOpacity(0.32),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> navShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 16,
      offset: const Offset(0, -4),
    ),
  ];

  // --- Global ThemeData ---
  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvasBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emerald600,
        primary: emerald600,
        secondary: rose600,
        surface: surfaceCard,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: slate900,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: slate900,
          letterSpacing: -0.3,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: slate800,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: slate800,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: slate700,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: slate500,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: slate400,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withOpacity(0.95),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: slate800),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: slate900,
        ),
        shape: const Border(
          bottom: BorderSide(color: slate100, width: 1),
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: slate100, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slate200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slate200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: emerald600, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: rose500, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: rose600, width: 1.5),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: slate500,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: slate400,
        ),
      ),
    );
  }
}

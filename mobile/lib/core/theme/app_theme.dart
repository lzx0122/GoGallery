import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme manages the application's visual style using FlexColorScheme.
///
/// Design Philosophy: "Intellectual Minimalism"
/// - Atmosphere: Quiet, Elegant, Content-focused.
/// - Whitespace: Generous use of whitespace.
/// - Radius: Soft rounded corners (12-16px).
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Define the Muted Terracotta color
  static const Color _terracottaPrimary = Color(0xFFE07A5F); // Muted Terracotta
  static const Color _terracottaSecondary = Color(
    0xFF3D405B,
  ); // Deep Blue/Charcoal

  // Define the Warm Off-white surface
  static const Color _lightSurface = Color(0xFFF4F1DE);
  static const Color _lightBackground = Color(0xFFFDFCF8);

  // Define the Soft Charcoal surface for dark mode
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkBackground = Color(0xFF121212);

  /// The light theme configuration.
  static ThemeData get lightTheme {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: _terracottaPrimary,
        secondary: _terracottaSecondary,
        appBarColor: _terracottaSecondary,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        defaultRadius: 12.0,
        elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
        elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
        outlinedButtonOutlineSchemeColor: SchemeColor.primary,
        toggleButtonsBorderSchemeColor: SchemeColor.primary,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 12.0,
        inputDecoratorUnfocusedHasBorder: true,
        inputDecoratorFillColor: _lightSurface,
        fabUseShape: true,
        fabRadius: 16.0,
        chipRadius: 12.0,
        cardRadius: 16.0,
        popupMenuRadius: 8.0,
      ),
      keyColors: const FlexKeyColors(useSecondary: true, useTertiary: true),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).copyWith(
      scaffoldBackgroundColor: _lightBackground,
      textTheme: _buildTextTheme(ThemeData.light().textTheme),
    );
  }

  /// The dark theme configuration.
  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: _terracottaPrimary,
        secondary: _terracottaSecondary,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        defaultRadius: 12.0,
        elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
        elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
        outlinedButtonOutlineSchemeColor: SchemeColor.primary,
        toggleButtonsBorderSchemeColor: SchemeColor.primary,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 12.0,
        inputDecoratorUnfocusedHasBorder: true,
        inputDecoratorFillColor: _darkSurface,
        fabUseShape: true,
        fabRadius: 16.0,
        chipRadius: 12.0,
        cardRadius: 16.0,
        popupMenuRadius: 8.0,
      ),
      keyColors: const FlexKeyColors(useSecondary: true, useTertiary: true),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).copyWith(
      scaffoldBackgroundColor: _darkBackground,
      textTheme: _buildTextTheme(ThemeData.dark().textTheme),
    );
  }

  /// Custom TextTheme combining Serif headings and Sans-Serif body.
  static TextTheme _buildTextTheme(TextTheme base) {
    final TextTheme baseTextTheme = GoogleFonts.interTextTheme(base);
    final TextTheme headingTextTheme = GoogleFonts.libreBaskervilleTextTheme(
      base,
    );

    return baseTextTheme.copyWith(
      displayLarge: headingTextTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      displayMedium: headingTextTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      displaySmall: headingTextTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: headingTextTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: headingTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: headingTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      titleLarge: headingTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

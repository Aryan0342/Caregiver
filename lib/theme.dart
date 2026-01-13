import 'package:flutter/material.dart';

/// Healthcare pictogram app theme with soft blue tones, rounded corners,
/// large buttons, and clear typography. Designed to be calm, modern, and accessible.
class AppTheme {
  // Soft blue color palette
  static const Color primaryBlue = Color(0xFF6BA3D8); // Soft, calming blue
  static const Color primaryBlueLight = Color(0xFF9BC4E8); // Lighter blue for backgrounds
  static const Color primaryBlueDark = Color(0xFF4A7FA8); // Darker blue for pressed states
  static const Color accentOrange = Color(0xFFFF8C42); // Warm accent for secondary actions
  static const Color accentGreen = Color(0xFF6BCB77); // Success/positive actions
  static const Color backgroundLight = Color(0xFFF5F7FA); // Very light background
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Pure white for cards
  static const Color textPrimary = Color(0xFF2C3E50); // Dark text for readability
  static const Color textSecondary = Color(0xFF7F8C8D); // Secondary text
  static const Color dividerColor = Color(0xFFE0E6ED); // Subtle dividers

  /// Main app theme - light mode only
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        primaryContainer: primaryBlueLight,
        secondary: accentOrange,
        secondaryContainer: Color(0xFFFFE4D1),
        surface: surfaceWhite,
        error: Color(0xFFE74C3C),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      // Scaffold background
      scaffoldBackgroundColor: backgroundLight,

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlueLight,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 28,
        ),
      ),

      // Text theme - large and readable
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.5,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.3,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.3,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.3,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.2,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.2,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 18, // Increased from 16 to 18
          fontWeight: FontWeight.normal,
          color: textPrimary,
          letterSpacing: 0.2,
          height: 1.6, // Increased line height for readability
        ),
        bodyMedium: TextStyle(
          fontSize: 16, // Increased from 14 to 16
          fontWeight: FontWeight.normal,
          color: textPrimary,
          letterSpacing: 0.1,
          height: 1.6, // Increased line height
        ),
        bodySmall: TextStyle(
          fontSize: 14, // Increased from 12 to 14
          fontWeight: FontWeight.normal,
          color: textSecondary,
          letterSpacing: 0.1,
          height: 1.6, // Increased line height
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.5,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.3,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.2,
          height: 1.4,
        ),
      ),

      // Elevated Button theme - large with rounded corners (accessibility optimized)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          minimumSize: const Size(120, 64), // Increased from 56 to 64 for better accessibility
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners
          ),
          textStyle: const TextStyle(
            fontSize: 20, // Increased from 18 to 20
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith<double>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return 1;
              }
              if (states.contains(WidgetState.disabled)) {
                return 0;
              }
              return 2;
            },
          ),
        ),
      ),

      // Filled Button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          minimumSize: const Size(120, 64), // Increased from 56 to 64
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 20, // Increased from 18 to 20
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          minimumSize: const Size(120, 64), // Increased from 56 to 64
          side: const BorderSide(color: primaryBlue, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 20, // Increased from 18 to 20
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(88, 56), // Increased from 48 to 56
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18, // Increased from 16 to 18
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Card theme - rounded corners with elevation
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Increased vertical spacing
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // Increased padding
        hintStyle: const TextStyle(
          color: textSecondary,
          fontSize: 18, // Increased from 16 to 18
        ),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18, // Increased from 16 to 18
          fontWeight: FontWeight.w500,
        ),
      ),

      // Floating Action Button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
        sizeConstraints: BoxConstraints.tightFor(width: 64, height: 64),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: primaryBlueLight,
        deleteIconColor: textPrimary,
        disabledColor: dividerColor,
        selectedColor: primaryBlue,
        secondarySelectedColor: primaryBlueLight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: textPrimary,
          height: 1.5,
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Helper method to get a custom button style for secondary actions (orange)
  static ButtonStyle get orangeButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: accentOrange,
      foregroundColor: Colors.white,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      minimumSize: const Size(120, 64), // Increased from 56 to 64
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontSize: 20, // Increased from 18 to 20
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Helper method to get a custom button style for success actions (green)
  static ButtonStyle get greenButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: accentGreen,
      foregroundColor: Colors.white,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      minimumSize: const Size(120, 64), // Increased from 56 to 64
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontSize: 20, // Increased from 18 to 20
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

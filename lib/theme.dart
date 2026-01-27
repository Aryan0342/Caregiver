import 'package:flutter/material.dart';

/// Healthcare pictogram app theme with neutral earth tones, rounded corners,
/// large buttons, and clear typography. Designed to be calm, modern, and accessible.
class AppTheme {
  // Color palette - neutral earth tones
  static const Color creamBeige = Color(0xFFF0E5D5); // Very light creamy beige - backgrounds
  static const Color warmTan = Color(0xFFD6BF99); // Medium warm tan - secondary actions
  static const Color mutedGreyBrown = Color(0xFF9A8C84); // Medium-dark muted grey-brown - primary
  static const Color coolGreyBeige = Color(0xFFC2BAB1); // Light-medium cool grey-beige - containers
  static const Color darkGreyBrown = Color(0xFF776E67); // Dark rich grey-brown - text and dark accents
  
  // Legacy color names for backward compatibility (mapped to new palette)
  static const Color primaryBlue = mutedGreyBrown; // Primary actions
  static const Color primaryBlueLight = coolGreyBeige; // Light backgrounds
  static const Color primaryBlueDark = darkGreyBrown; // Darker states
  static const Color accentOrange = warmTan; // Secondary actions
  static const Color accentGreen = Color(0xFF4CAF50); // Success/positive actions - soft green
  static const Color backgroundLight = creamBeige; // Very light background
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Pure white for cards
  static const Color textPrimary = darkGreyBrown; // Dark text for readability
  static const Color textSecondary = mutedGreyBrown; // Secondary text
  static const Color dividerColor = coolGreyBeige; // Subtle dividers

  /// Main app theme - light mode only
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: mutedGreyBrown,
        primaryContainer: coolGreyBeige,
        secondary: warmTan,
        secondaryContainer: Color(0xFFE8DDCD), // Lighter warm tan
        surface: surfaceWhite,
        error: Color(0xFFE74C3C), // Keep red for errors
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      // Scaffold background
      scaffoldBackgroundColor: backgroundLight,

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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
          backgroundColor: mutedGreyBrown,
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
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return mutedGreyBrown.withValues(alpha: 0.5);
              }
              return mutedGreyBrown;
            },
          ),
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
          backgroundColor: mutedGreyBrown,
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
          foregroundColor: mutedGreyBrown,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          minimumSize: const Size(120, 64), // Increased from 56 to 64
          side: const BorderSide(color: mutedGreyBrown, width: 2),
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
          foregroundColor: mutedGreyBrown,
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
        shadowColor: Colors.black.withValues(alpha: 0.1),
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
          borderSide: const BorderSide(color: mutedGreyBrown, width: 2),
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
        backgroundColor: mutedGreyBrown,
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
        backgroundColor: coolGreyBeige,
        deleteIconColor: textPrimary,
        disabledColor: dividerColor,
        selectedColor: mutedGreyBrown,
        secondarySelectedColor: coolGreyBeige,
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
        selectedItemColor: mutedGreyBrown,
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
        backgroundColor: darkGreyBrown,
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

  /// Helper method to get a custom button style for secondary actions (warm tan)
  static ButtonStyle get orangeButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: warmTan,
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

  /// Helper method to get a custom button style for success actions
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

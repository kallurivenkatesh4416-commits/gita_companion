import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _paper = Color(0xFFF6ECDB);
  static const Color _surface = Color(0xFFFFFAF1);
  static const Color _ink = Color(0xFF201A14);
  static const Color _inkMuted = Color(0xFF635647);
  static const Color _primary = Color(0xFF92431A);
  static const Color _secondary = Color(0xFF2E645E);
  static const Color _outline = Color(0xFFCCB89C);
  static const Color _surfaceTint = Color(0xFFF0DFC7);
  static const Color _darkBackground = Color(0xFF1A1410);
  static const Color _darkSurface = Color(0xFF2A221A);
  static const Color _darkInk = Color(0xFFE8D5B8);
  static const Color _darkInkMuted = Color(0xFFC8B79E);
  static const Color _darkPrimary = Color(0xFFD4915A);
  static const Color _darkSecondary = Color(0xFF77A99F);
  static const Color _darkOutline = Color(0xFF594B3D);
  static const Color _darkSurfaceTint = Color(0xFF3A2F24);

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _primary,
      onPrimary: Colors.white,
      secondary: _secondary,
      onSecondary: Colors.white,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: _surface,
      onSurface: _ink,
      surfaceContainerHighest: _surfaceTint,
      onSurfaceVariant: _inkMuted,
      outline: _outline,
      shadow: Color(0x26000000),
      inverseSurface: Color(0xFF2A2520),
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFFFFD4B4),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _paper,
    );

    final textTheme =
        GoogleFonts.sourceSerif4TextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.cormorantGaramond(
        textStyle: base.textTheme.headlineLarge,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      headlineMedium: GoogleFonts.cormorantGaramond(
        textStyle: base.textTheme.headlineMedium,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      headlineSmall: GoogleFonts.cormorantGaramond(
        textStyle: base.textTheme.headlineSmall,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.cormorantGaramond(
        textStyle: base.textTheme.titleLarge,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.sourceSans3(
        textStyle: base.textTheme.titleMedium,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.sourceSans3(
        textStyle: base.textTheme.titleSmall,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.sourceSans3(textStyle: base.textTheme.bodyLarge),
      bodyMedium: GoogleFonts.sourceSans3(textStyle: base.textTheme.bodyMedium),
      bodySmall: GoogleFonts.sourceSans3(textStyle: base.textTheme.bodySmall),
      labelLarge: GoogleFonts.sourceSans3(
        textStyle: base.textTheme.labelLarge,
        fontWeight: FontWeight.w700,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.secondary.withValues(alpha: 0.16),
        labelStyle: textTheme.bodySmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: colorScheme.outline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: colorScheme.surface,
      ),
      dividerColor: colorScheme.outline.withValues(alpha: 0.45),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _darkPrimary,
      onPrimary: Color(0xFF25180F),
      secondary: _darkSecondary,
      onSecondary: Color(0xFF10211F),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: _darkSurface,
      onSurface: _darkInk,
      surfaceContainerHighest: _darkSurfaceTint,
      onSurfaceVariant: _darkInkMuted,
      outline: _darkOutline,
      shadow: Color(0x66000000),
      inverseSurface: Color(0xFFF6ECDB),
      onInverseSurface: Color(0xFF241C15),
      inversePrimary: _primary,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkBackground,
    );

    final textTheme =
        GoogleFonts.sourceSerif4TextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.cormorantGaramond(
        textStyle: base.textTheme.headlineLarge,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      headlineMedium: GoogleFonts.cormorantGaramond(
        textStyle: base.textTheme.headlineMedium,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      headlineSmall: GoogleFonts.cormorantGaramond(
        textStyle: base.textTheme.headlineSmall,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.cormorantGaramond(
        textStyle: base.textTheme.titleLarge,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.sourceSans3(
        textStyle: base.textTheme.titleMedium,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.sourceSans3(
        textStyle: base.textTheme.titleSmall,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.sourceSans3(textStyle: base.textTheme.bodyLarge),
      bodyMedium: GoogleFonts.sourceSans3(textStyle: base.textTheme.bodyMedium),
      bodySmall: GoogleFonts.sourceSans3(textStyle: base.textTheme.bodySmall),
      labelLarge: GoogleFonts.sourceSans3(
        textStyle: base.textTheme.labelLarge,
        fontWeight: FontWeight.w700,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.55)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.6)),
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.secondary.withValues(alpha: 0.2),
        labelStyle: textTheme.bodySmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: colorScheme.outline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: colorScheme.surface,
      ),
      dividerColor: colorScheme.outline.withValues(alpha: 0.55),
    );
  }

  static TextStyle sanskritStyle(
    BuildContext context, {
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    final base = Theme.of(context).textTheme.bodyLarge;
    return GoogleFonts.cormorantGaramond(
      textStyle: base,
      fontStyle: FontStyle.italic,
      fontWeight: fontWeight,
      fontSize: fontSize ?? (base?.fontSize ?? 19),
      height: 1.55,
      letterSpacing: 0.18,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
}

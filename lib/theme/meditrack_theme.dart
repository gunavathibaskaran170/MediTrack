import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Spacing System constants
class MediTrackSpacing {
  static const double screenHorizontalPadding = 16.0;
  static const double cardInternalPaddingHorizontal = 16.0;
  static const double cardInternalPaddingVertical = 14.0;
  static const double sectionGap = 12.0;
  static const double titleToContentGap = 8.0;
  static const double listItemGap = 8.0;
  static const double formFieldGap = 14.0;
  static const double iconToTextGap = 8.0;
  static const double small = 4.0;
  static const double medium = 12.0;
  static const double large = 24.0;
  static const double xl = 32.0;
}

/// Border Radius System constants
class MediTrackRadius {
  static const double inputFields = 10.0;
  static const double buttons = 10.0;
  static const double cards = 14.0;
  static const double chipsBadges = 8.0;
  static const double bottomSheets = 20.0;
}

/// Custom Theme Extension for MediTrack Colors
class MediTrackThemeExtension extends ThemeExtension<MediTrackThemeExtension> {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color accentLight;
  final Color background;
  final Color card;
  final Color errorSos;
  final Color errorLight;
  final Color warning;
  final Color warningLight;
  final Color success;
  final Color successLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color dividerColor;
  final Color shadowColor;

  const MediTrackThemeExtension({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.accentLight,
    required this.background,
    required this.card,
    required this.errorSos,
    required this.errorLight,
    required this.warning,
    required this.warningLight,
    required this.success,
    required this.successLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.dividerColor,
    required this.shadowColor,
  });

  @override
  ThemeExtension<MediTrackThemeExtension> copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? accent,
    Color? accentLight,
    Color? background,
    Color? card,
    Color? errorSos,
    Color? errorLight,
    Color? warning,
    Color? warningLight,
    Color? success,
    Color? successLight,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? dividerColor,
    Color? shadowColor,
  }) {
    return MediTrackThemeExtension(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      background: background ?? this.background,
      card: card ?? this.card,
      errorSos: errorSos ?? this.errorSos,
      errorLight: errorLight ?? this.errorLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      dividerColor: dividerColor ?? this.dividerColor,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  ThemeExtension<MediTrackThemeExtension> lerp(
    covariant ThemeExtension<MediTrackThemeExtension>? other,
    double t,
  ) {
    if (other is! MediTrackThemeExtension) return this;
    return MediTrackThemeExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      errorSos: Color.lerp(errorSos, other.errorSos, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}

/// Global MediTrack Theme Setup
class MediTrackTheme {
  static const colors = MediTrackThemeExtension(
    primary: Color(0xFF3D3B8E),
    primaryLight: Color(0xFFEEEDFE),
    primaryDark: Color(0xFF26215C),
    accent: Color(0xFF1D9E75),
    accentLight: Color(0xFFE1F5EE),
    background: Color(0xFFF7F6F2),
    card: Color(0xFFFFFFFF),
    errorSos: Color(0xFFC0392B),
    errorLight: Color(0xFFFAECE7),
    warning: Color(0xFFE08C00),
    warningLight: Color(0xFFFAEEDA),
    success: Color(0xFF27760A),
    successLight: Color(0xFFEAF3DE),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF5F5E7A),
    textHint: Color(0xFF9E9DB8),
    dividerColor: Color(0xFFE2E1EF),
    shadowColor: Color(0x0F3D3B8E),
  );

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: colors.background,
      
      // Card Theme Setup
      cardTheme: CardTheme(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MediTrackRadius.cards),
          side: BorderSide(color: colors.dividerColor, width: 0.8),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: MediTrackSpacing.screenHorizontalPadding,
          vertical: 6,
        ),
      ),

      // AppBar Theme Setup
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),

      // Bottom Navigation Theme Setup
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.card,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // ElevatedButton Theme Setup
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediTrackRadius.buttons),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // OutlinedButton Theme Setup
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediTrackRadius.buttons),
          ),
          textStyle: GoogleFonts.inter(fontSize: 14),
        ),
      ),

      // Input Decoration Theme Setup
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.primaryLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MediTrackRadius.inputFields),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MediTrackRadius.inputFields),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: colors.textSecondary,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: colors.textHint,
        ),
        prefixIconColor: colors.primary,
      ),

      // Chip Theme Setup
      chipTheme: ChipThemeData(
        backgroundColor: colors.primaryLight,
        selectedColor: colors.primary,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: colors.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MediTrackRadius.chipsBadges),
        ),
        side: BorderSide(color: colors.dividerColor, width: 0.8),
      ),

      // Divider Theme Setup
      dividerTheme: DividerThemeData(
        color: colors.dividerColor,
        thickness: 0.8,
      ),

      // Switch Theme Setup
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(colors.primary),
        trackColor: WidgetStateProperty.all(colors.primaryLight),
      ),

      // Register Theme Extensions
      extensions: const <ThemeExtension<dynamic>>[colors],
      textTheme: baseTextTheme,
    );
  }
}

/// Helper BuildContext extension for concise style reference access
extension MediTrackThemeContext on BuildContext {
  MediTrackThemeExtension get colors => Theme.of(this).extension<MediTrackThemeExtension>()!;
  
  TextTheme get baseTextTheme => Theme.of(this).textTheme;

  // Visual Typography System Getters
  TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      );

  TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      );

  TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      );

  TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colors.textPrimary,
      );

  TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
      );

  TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
      );

  TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
      );

  TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
      );

  TextStyle get vitalValue => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      );

  TextStyle get vitalUnit => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
      );
}

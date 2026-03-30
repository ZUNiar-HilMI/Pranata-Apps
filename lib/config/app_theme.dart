import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Default (SuperAdmin / Global) — Navy & Gold
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  static const Color navyDark  = Color(0xFF0D1B2E);
  static const Color navyMid   = Color(0xFF152237);
  static const Color navyLight = Color(0xFF1E3A5F);
  static const Color navyCard  = Color(0xFF1A2E47);

  static const Color goldLight = Color(0xFFE8C97A);
  static const Color goldMid   = Color(0xFFCDA84A);
  static const Color goldDark  = Color(0xFFA07830);

  static const Color textPrimary   = Color(0xFFF5E6C8);
  static const Color textSecondary = Color(0xFF9B8A6E);
  static const Color textHint      = Color(0xFF6B7B6E);

  static const Color success = Color(0xFF4CAF82);
  static const Color error   = Color(0xFFE57373);
  static const Color warning = Color(0xFFFFB74D);
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-Dinas Color Palettes
// ─────────────────────────────────────────────────────────────────────────────

/// Kominfo — Biru Tua + Cyan
class KominfoColors {
  static const Color dark    = Color(0xFF0A1929);
  static const Color mid     = Color(0xFF0D2B6E);
  static const Color light   = Color(0xFF1565C0);
  static const Color card    = Color(0xFF0F2952);
  static const Color accent  = Color(0xFF00B4D8);
  static const Color accentL = Color(0xFF90E0EF);
  static const Color accentD = Color(0xFF0077B6);
}

/// DLH — Hijau Tua + Hijau Muda
class DlhColors {
  static const Color dark    = Color(0xFF0D1F12);
  static const Color mid     = Color(0xFF1A4731);
  static const Color light   = Color(0xFF2D6A4F);
  static const Color card    = Color(0xFF1B3D29);
  static const Color accent  = Color(0xFF52B788);
  static const Color accentL = Color(0xFFB7E4C7);
  static const Color accentD = Color(0xFF2D6A4F);
}

/// Dishub — Merah Tua + Oranye
class DishubColors {
  static const Color dark    = Color(0xFF1A0A0A);
  static const Color mid     = Color(0xFF6D1A1A);
  static const Color light   = Color(0xFF8B2500);
  static const Color card    = Color(0xFF521515);
  static const Color accent  = Color(0xFFE07B39);
  static const Color accentL = Color(0xFFF4A261);
  static const Color accentD = Color(0xFFAE4700);
}

// ─────────────────────────────────────────────────────────────────────────────
// DinasTheme — factory per dinas
// ─────────────────────────────────────────────────────────────────────────────

class DinasTheme {
  /// Kembalikan ThemeData sesuai dinasId user.
  /// Jika dinasId null / tidak dikenal → default Navy-Gold (superadmin).
  static ThemeData getTheme(String? dinasId) {
    switch (dinasId) {
      case 'kominfo':
        return _buildTheme(
          dark:    KominfoColors.dark,
          mid:     KominfoColors.mid,
          light:   KominfoColors.light,
          card:    KominfoColors.card,
          accent:  KominfoColors.accent,
          accentL: KominfoColors.accentL,
          accentD: KominfoColors.accentD,
        );
      case 'dlh':
        return _buildTheme(
          dark:    DlhColors.dark,
          mid:     DlhColors.mid,
          light:   DlhColors.light,
          card:    DlhColors.card,
          accent:  DlhColors.accent,
          accentL: DlhColors.accentL,
          accentD: DlhColors.accentD,
        );
      case 'dishub':
        return _buildTheme(
          dark:    DishubColors.dark,
          mid:     DishubColors.mid,
          light:   DishubColors.light,
          card:    DishubColors.card,
          accent:  DishubColors.accent,
          accentL: DishubColors.accentL,
          accentD: DishubColors.accentD,
        );
      default:
        return AppTheme.themeData; // superadmin / fallback
    }
  }

  /// Kembalikan warna aksen utama untuk dinas (untuk widget kecil tanpa full theme).
  static Color primaryAccent(String? dinasId) {
    switch (dinasId) {
      case 'kominfo': return KominfoColors.accent;
      case 'dlh':     return DlhColors.accent;
      case 'dishub':  return DishubColors.accent;
      default:        return AppColors.goldMid;
    }
  }

  static Color accentLight(String? dinasId) {
    switch (dinasId) {
      case 'kominfo': return KominfoColors.accentL;
      case 'dlh':     return DlhColors.accentL;
      case 'dishub':  return DishubColors.accentL;
      default:        return AppColors.goldLight;
    }
  }

  static Color darkBg(String? dinasId) {
    switch (dinasId) {
      case 'kominfo': return KominfoColors.dark;
      case 'dlh':     return DlhColors.dark;
      case 'dishub':  return DishubColors.dark;
      default:        return AppColors.navyDark;
    }
  }

  static Color cardBg(String? dinasId) {
    switch (dinasId) {
      case 'kominfo': return KominfoColors.card;
      case 'dlh':     return DlhColors.card;
      case 'dishub':  return DishubColors.card;
      default:        return AppColors.navyCard;
    }
  }

  static String dinasLabel(String? dinasId) {
    switch (dinasId) {
      case 'kominfo': return 'Dinas Komunikasi dan Informatika';
      case 'dlh':     return 'Dinas Lingkungan Hidup';
      case 'dishub':  return 'Dinas Perhubungan';
      default:        return 'Super Admin';
    }
  }

  static String dinasCode(String? dinasId) {
    switch (dinasId) {
      case 'kominfo': return 'KOMINFO';
      case 'dlh':     return 'DLH';
      case 'dishub':  return 'DISHUB';
      default:        return 'SA';
    }
  }

  // ─── Internal builder ───────────────────────────────────────────────────
  static ThemeData _buildTheme({
    required Color dark,
    required Color mid,
    required Color light,
    required Color card,
    required Color accent,
    required Color accentL,
    required Color accentD,
  }) {
    const Color textPrimary   = Color(0xFFF0F4F8);
    const Color textSecondary = Color(0xFFAEC0CC);
    const Color textHint      = Color(0xFF6B8A99);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: dark,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accentL,
        surface: mid,
        error: AppColors.error,
        onPrimary: dark,
        onSecondary: dark,
        onSurface: textPrimary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: dark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentL),
        titleTextStyle: TextStyle(
          color: accentL,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: accent, width: 0.4),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: light,
        hintStyle: const TextStyle(color: textHint),
        labelStyle: const TextStyle(color: textSecondary),
        floatingLabelStyle: TextStyle(color: accentL),
        prefixIconColor: accent,
        suffixIconColor: accent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentL, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withOpacity(0.4),
        selectionHandleColor: accentL,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: dark,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          elevation: 3,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentL,
          side: BorderSide(color: accent, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentL),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: mid,
        selectedItemColor: accentL,
        unselectedItemColor: textSecondary,
        elevation: 10,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: accentL,
        unselectedLabelColor: textSecondary,
        indicatorColor: accent,
      ),

      dividerTheme: DividerThemeData(color: accent, thickness: 0.3),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: dark,
      ),

      textTheme: TextTheme(
        headlineLarge: TextStyle(color: accentL, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: accentL, fontWeight: FontWeight.bold),
        headlineSmall: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(color: textPrimary),
        titleSmall: const TextStyle(color: textSecondary),
        bodyLarge: const TextStyle(color: textPrimary),
        bodyMedium: const TextStyle(color: textPrimary),
        bodySmall: const TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: dark, fontWeight: FontWeight.bold),
      ),

      iconTheme: IconThemeData(color: accentL),
      primaryIconTheme: IconThemeData(color: accentL),

      chipTheme: ChipThemeData(
        backgroundColor: light,
        labelStyle: const TextStyle(color: textPrimary),
        side: BorderSide(color: accent, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: mid,
        titleTextStyle: TextStyle(color: accentL, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accent, width: 0.5),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: const TextStyle(color: textPrimary),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accent.withOpacity(0.4)
              : light,
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: card,
        textStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: accent, width: 0.4),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Default App Theme (SuperAdmin / Navy-Gold)
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.navyDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.goldMid,
      secondary: AppColors.goldLight,
      surface: AppColors.navyMid,
      error: AppColors.error,
      onPrimary: AppColors.navyDark,
      onSecondary: AppColors.navyDark,
      onSurface: AppColors.textPrimary,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navyDark,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.goldLight),
      titleTextStyle: TextStyle(
        color: AppColors.goldLight,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.navyCard,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.goldMid, width: 0.4),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.navyLight,
      hintStyle: const TextStyle(color: AppColors.textHint),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      floatingLabelStyle: const TextStyle(color: AppColors.goldLight),
      prefixIconColor: AppColors.goldMid,
      suffixIconColor: AppColors.goldMid,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.goldMid, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.goldMid, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.goldLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.goldMid,
      selectionColor: AppColors.goldMid,
      selectionHandleColor: AppColors.goldLight,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.goldMid,
        foregroundColor: AppColors.navyDark,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        elevation: 3,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.goldLight,
        side: const BorderSide(color: AppColors.goldMid, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.goldLight),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.navyMid,
      selectedItemColor: AppColors.goldLight,
      unselectedItemColor: AppColors.textSecondary,
      elevation: 10,
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.goldLight,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.goldMid,
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.goldMid,
      thickness: 0.3,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.goldMid,
      foregroundColor: AppColors.navyDark,
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: AppColors.textPrimary),
      titleSmall: TextStyle(color: AppColors.textSecondary),
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      bodySmall: TextStyle(color: AppColors.textSecondary),
      labelLarge: TextStyle(color: AppColors.navyDark, fontWeight: FontWeight.bold),
    ),

    iconTheme: const IconThemeData(color: AppColors.goldLight),
    primaryIconTheme: const IconThemeData(color: AppColors.goldLight),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.navyLight,
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      side: const BorderSide(color: AppColors.goldMid, width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.navyMid,
      titleTextStyle: const TextStyle(
        color: AppColors.goldLight,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.goldMid, width: 0.5),
      ),
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.navyCard,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.goldMid : AppColors.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.goldMid.withOpacity(0.4)
            : AppColors.navyLight,
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.navyCard,
      textStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.goldMid, width: 0.4),
      ),
    ),
  );

  // Helper: gold gradient decoration for buttons
  static BoxDecoration get goldGradientButton => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.goldLight, AppColors.goldMid, AppColors.goldDark],
    ),
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: AppColors.goldMid.withOpacity(0.4),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

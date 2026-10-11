import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/gen/colors.gen.dart' show AppColors;
import 'package:paypadi/gen/fonts.gen.dart';

/// The colours screens use, by role, for the light and the dark theme.
///
/// Read it with `context.palette`. The light palette is the original design;
/// the dark one keeps the brand teal and the user's chosen accent, and moves
/// everything else onto cool near-black surfaces. The grey ramp keeps its
/// meaning in both: 50 is the subtlest tint of the background and 700 the
/// strongest secondary text, so in the dark palette the values run the other
/// way.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.scaffoldBackground,
    required this.onSurface,
    required this.onPrimary,
    required this.grey50,
    required this.grey200,
    required this.grey300,
    required this.grey400,
    required this.grey500,
    required this.grey600,
    required this.grey700,
    required this.disabled,
    required this.hintText,
    required this.unfocusedTextField,
    required this.amountDisplayBorderColor,
    required this.bankBorderColor,
    required this.dividerColor,
    required this.themeBorderColor,
    required this.walletCardTextColor,
    required this.walletCardIconColor,
    required this.unselectedIndicator,
    required this.boxShadow,
    required this.referralCardColor,
    required this.success,
    required this.failure,
  });

  /// Behind every screen.
  final Color background;

  /// Cards, sheets, text fields and anything else raised off the background.
  final Color surface;

  /// A quieter area set into the background (e.g. grouped sections).
  final Color scaffoldBackground;

  /// Main text and icons.
  final Color onSurface;

  /// Text and icons drawn on the primary colour.
  final Color onPrimary;

  final Color grey50;
  final Color grey200;
  final Color grey300;
  final Color grey400;
  final Color grey500;
  final Color grey600;
  final Color grey700;

  /// Fill for disabled controls and empty placeholders.
  final Color disabled;
  final Color hintText;
  final Color unfocusedTextField;
  final Color amountDisplayBorderColor;
  final Color bankBorderColor;
  final Color dividerColor;
  final Color themeBorderColor;
  final Color walletCardTextColor;
  final Color walletCardIconColor;
  final Color unselectedIndicator;
  final Color boxShadow;
  final Color referralCardColor;
  final Color success;
  final Color failure;

  static const light = AppPalette(
    background: AppColors.white,
    surface: AppColors.white,
    scaffoldBackground: AppColors.scaffoldBackground,
    onSurface: AppColors.black,
    onPrimary: AppColors.white,
    grey50: AppColors.grey50,
    grey200: AppColors.grey200,
    grey300: AppColors.grey300,
    grey400: AppColors.grey400,
    grey500: AppColors.grey500,
    grey600: AppColors.grey600,
    grey700: AppColors.grey700,
    disabled: AppColors.disabled,
    hintText: AppColors.hintText,
    unfocusedTextField: AppColors.unfocusedTextField,
    amountDisplayBorderColor: AppColors.amountDisplayBorderColor,
    bankBorderColor: AppColors.bankBorderColor,
    dividerColor: AppColors.dividerColor,
    themeBorderColor: AppColors.themeBorderColor,
    walletCardTextColor: AppColors.walletCardTextColor,
    walletCardIconColor: AppColors.walletCardIconColor,
    unselectedIndicator: AppColors.unselectedIndicator,
    boxShadow: AppColors.boxShadow,
    referralCardColor: AppColors.referralCardColor,
    success: AppColors.success,
    failure: AppColors.failure,
  );

  static const dark = AppPalette(
    background: Color(0xFF0E1316),
    surface: Color(0xFF161D21),
    scaffoldBackground: Color(0xFF1C2429),
    onSurface: Color(0xFFEEF2F4),
    onPrimary: AppColors.white,
    grey50: Color(0xFF1A2125),
    grey200: Color(0xFF2A3338),
    grey300: Color(0xFF3A444A),
    grey400: Color(0xFF6B767D),
    grey500: Color(0xFF8D979E),
    grey600: Color(0xFFA7B0B6),
    grey700: Color(0xFFC9D0D4),
    disabled: Color(0xFF2A3338),
    hintText: Color(0xFF6F7A81),
    unfocusedTextField: Color(0xFF33404A),
    amountDisplayBorderColor: Color(0xFF3A454C),
    bankBorderColor: Color(0xFF263036),
    dividerColor: Color(0xFF222B30),
    themeBorderColor: Color(0xFF2A3338),
    walletCardTextColor: Color(0xFFEEF2F4),
    walletCardIconColor: Color(0xFF8D979E),
    unselectedIndicator: Color(0xFF3A444A),
    boxShadow: Color(0xFF000000),
    referralCardColor: Color(0xFF12312D),
    success: Color(0xFF34C38F),
    failure: Color(0xFFFF5A52),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      scaffoldBackground: mix(scaffoldBackground, other.scaffoldBackground),
      onSurface: mix(onSurface, other.onSurface),
      onPrimary: mix(onPrimary, other.onPrimary),
      grey50: mix(grey50, other.grey50),
      grey200: mix(grey200, other.grey200),
      grey300: mix(grey300, other.grey300),
      grey400: mix(grey400, other.grey400),
      grey500: mix(grey500, other.grey500),
      grey600: mix(grey600, other.grey600),
      grey700: mix(grey700, other.grey700),
      disabled: mix(disabled, other.disabled),
      hintText: mix(hintText, other.hintText),
      unfocusedTextField: mix(unfocusedTextField, other.unfocusedTextField),
      amountDisplayBorderColor: mix(
        amountDisplayBorderColor,
        other.amountDisplayBorderColor,
      ),
      bankBorderColor: mix(bankBorderColor, other.bankBorderColor),
      dividerColor: mix(dividerColor, other.dividerColor),
      themeBorderColor: mix(themeBorderColor, other.themeBorderColor),
      walletCardTextColor: mix(walletCardTextColor, other.walletCardTextColor),
      walletCardIconColor: mix(walletCardIconColor, other.walletCardIconColor),
      unselectedIndicator: mix(unselectedIndicator, other.unselectedIndicator),
      boxShadow: mix(boxShadow, other.boxShadow),
      referralCardColor: mix(referralCardColor, other.referralCardColor),
      success: mix(success, other.success),
      failure: mix(failure, other.failure),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The palette for the current theme (light or dark). Falls back to the
  /// palette matching the theme's brightness when a widget is shown outside
  /// the app's theme, e.g. in a test.
  AppPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);
  }
}

class AppTheme {
  const AppTheme({required this.primary});
  final Color primary;

  ThemeData theme() => _build(Brightness.light, AppPalette.light);

  ThemeData darkTheme() => _build(Brightness.dark, AppPalette.dark);

  ThemeData _build(Brightness brightness, AppPalette palette) {
    final textStyle = TextStyle(
      letterSpacing: 0.5,
      color: palette.onSurface,
      fontWeight: FontWeight.w500,
    );
    // Light keeps Material's defaults wherever the original design did, so
    // only the dark theme sets dividers, sheets, dialogs and search colours.
    final isDark = brightness == Brightness.dark;
    // Teal text and outlines are too dim on near-black, so the dark theme
    // draws them in a lighter tint of the user's accent.
    final accent = isDark
        ? Color.lerp(primary, palette.onPrimary, .3)!
        : primary;
    final colorScheme = !isDark
        ? ColorScheme.light(primary: primary)
        : ColorScheme.dark(
            primary: primary,
            onPrimary: palette.onPrimary,
            surface: palette.surface,
            onSurface: palette.onSurface,
            error: palette.failure,
          );

    return ThemeData(
      brightness: brightness,
      fontFamily: FontFamily.manrope,
      colorScheme: colorScheme,
      extensions: [palette],
      scaffoldBackgroundColor: palette.background,
      dividerColor: isDark ? palette.dividerColor : null,
      appBarTheme: AppBarTheme(
        elevation: Values.zero,
        scrolledUnderElevation: Values.zero,
        backgroundColor: palette.background,
        foregroundColor: palette.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: 16.sp,
              letterSpacing: Values.zero,
            ),
          ),
          fixedSize: WidgetStatePropertyAll(kButtonSize),
          foregroundColor: WidgetStatePropertyAll(palette.onPrimary),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Values.v12.r),
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            return states.contains(WidgetState.disabled)
                ? palette.disabled
                : primary;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: 16.sp,
              letterSpacing: Values.zero,
            ),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: accent)),
          fixedSize: WidgetStatePropertyAll(kButtonSize),
          foregroundColor: WidgetStatePropertyAll(accent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Values.v12.r),
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        constraints: BoxConstraints(maxWidth: 362.w),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Values.v16,
          vertical: Values.v8,
        ),
        hintStyle: TextStyle(
          fontSize: 14.sp,
          letterSpacing: Values.zero,
          color: palette.hintText,
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: palette.unfocusedTextField),
          borderRadius: BorderRadius.circular(Values.v12.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accent),
          borderRadius: BorderRadius.circular(Values.v12.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: palette.unfocusedTextField),
          borderRadius: BorderRadius.circular(Values.v12.r),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Values.v18.r),
          borderSide: BorderSide(color: palette.failure),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Values.v18.r),
          borderSide: BorderSide(color: palette.failure),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(Values.zero),
        backgroundColor: isDark
            ? WidgetStatePropertyAll(palette.surface)
            : null,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            side: BorderSide(color: palette.unfocusedTextField),
            borderRadius: BorderRadius.circular(Values.v12.r),
          ),
        ),
      ),
      searchViewTheme: SearchViewThemeData(
        backgroundColor: isDark ? palette.surface : null,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: palette.unfocusedTextField),
          borderRadius: BorderRadius.circular(Values.v12.r),
        ),
      ),
      bottomSheetTheme: isDark
          ? BottomSheetThemeData(
              backgroundColor: palette.surface,
              modalBackgroundColor: palette.surface,
            )
          : null,
      dialogTheme: isDark
          ? DialogThemeData(backgroundColor: palette.surface)
          : null,
      textTheme: TextTheme(
        displaySmall: textStyle,
        headlineLarge: textStyle,
        headlineMedium: textStyle,
        headlineSmall: textStyle,
        titleLarge: textStyle,
        titleMedium: textStyle,
        titleSmall: textStyle,
        bodyLarge: textStyle,
        bodyMedium: textStyle,
        bodySmall: textStyle,
        labelLarge: textStyle,
        labelMedium: textStyle,
        labelSmall: textStyle,
      ),
    );
  }
}

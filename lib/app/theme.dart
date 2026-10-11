import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/gen/colors.gen.dart' show AppColors;
import 'package:paypadi/gen/fonts.gen.dart';

class AppTheme {
  const AppTheme({required this.primary});
  final Color primary;

  ThemeData theme() => ThemeData(
    brightness: Brightness.light,
    fontFamily: FontFamily.manrope,
    colorScheme: ColorScheme.light(primary: primary),
    scaffoldBackgroundColor: AppColors.white,
    appBarTheme: const AppBarTheme(
      elevation: Values.zero,
      scrolledUnderElevation: Values.zero,
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
        foregroundColor: const WidgetStatePropertyAll(AppColors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Values.v12.r),
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.disabled)
              ? AppColors.disabled
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
        side: WidgetStatePropertyAll(BorderSide(color: primary)),
        fixedSize: WidgetStatePropertyAll(kButtonSize),
        foregroundColor: WidgetStatePropertyAll(primary),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Values.v12.r),
          ),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      constraints: BoxConstraints(maxWidth: 362.w),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Values.v16,
        vertical: Values.v8,
      ),
      hintStyle: TextStyle(
        fontSize: 14.sp,
        letterSpacing: Values.zero,
        color: AppColors.hintText,
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.unfocusedTextField),
        borderRadius: BorderRadius.circular(Values.v12.r),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primary),
        borderRadius: BorderRadius.circular(Values.v12.r),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.unfocusedTextField),
        borderRadius: BorderRadius.circular(Values.v12.r),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Values.v18.r),
        borderSide: const BorderSide(color: AppColors.failure),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Values.v18.r),
        borderSide: const BorderSide(color: AppColors.failure),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(Values.zero),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.unfocusedTextField),
          borderRadius: BorderRadius.circular(Values.v12.r),
        ),
      ),
    ),
    searchViewTheme: SearchViewThemeData(
      // elevation: Values.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.unfocusedTextField),
        borderRadius: BorderRadius.circular(Values.v12.r),
      ),
    ),
    textTheme: const TextTheme(
      displaySmall: _appTextStyle,
      headlineLarge: _appTextStyle,
      headlineMedium: _appTextStyle,
      headlineSmall: _appTextStyle,
      titleLarge: _appTextStyle,
      titleMedium: _appTextStyle,
      titleSmall: _appTextStyle,
      bodyLarge: _appTextStyle,
      bodyMedium: _appTextStyle,
      bodySmall: _appTextStyle,
      labelLarge: _appTextStyle,
      labelMedium: _appTextStyle,
      labelSmall: _appTextStyle,
    ),
  );
}

const TextStyle _appTextStyle = TextStyle(
  letterSpacing: 0.5,
  color: AppColors.black,
  fontWeight: FontWeight.w500,
);

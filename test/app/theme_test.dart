import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/app/theme.dart';
import 'package:paypadi/gen/assets.gen.dart';
import 'package:paypadi/gen/colors.gen.dart';
import 'package:paypadi/shared/extensions/themed_svg.dart';

const _theme = AppTheme(primary: AppColors.primary);

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

/// Builds [child] under the app's themes in [mode], with ScreenUtil ready.
Future<void> pumpThemed(
  WidgetTester tester,
  ThemeMode mode,
  Widget child,
) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        theme: _theme.theme(),
        darkTheme: _theme.darkTheme(),
        themeMode: mode,
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the light theme keeps the original design', (tester) async {
    late ThemeData theme;
    await pumpThemed(
      tester,
      ThemeMode.light,
      Builder(
        builder: (context) {
          theme = Theme.of(context);
          return const SizedBox();
        },
      ),
    );

    expect(theme.brightness, Brightness.light);
    expect(theme.extension<AppPalette>(), AppPalette.light);
    expect(theme.scaffoldBackgroundColor, AppColors.white);
    expect(theme.textTheme.bodyMedium?.color, AppColors.black);
    expect(theme.inputDecorationTheme.fillColor, AppColors.white);
  });

  testWidgets('dark mode switches the palette, background and text', (
    tester,
  ) async {
    late AppPalette palette;
    late ThemeData theme;
    await pumpThemed(
      tester,
      ThemeMode.dark,
      Builder(
        builder: (context) {
          palette = context.palette;
          theme = Theme.of(context);
          return const SizedBox();
        },
      ),
    );

    expect(palette, AppPalette.dark);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppPalette.dark.background);
    expect(theme.textTheme.bodyMedium?.color, AppPalette.dark.onSurface);
    expect(theme.colorScheme.primary, AppColors.primary);
  });

  testWidgets('one-colour icons follow the theme so they stay visible in '
      'dark mode', (tester) async {
    await pumpThemed(
      tester,
      ThemeMode.dark,
      Builder(builder: (context) => AppAssets.icons.icProfile.themed(context)),
    );

    final icon = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      icon.colorFilter,
      ColorFilter.mode(AppPalette.dark.onSurface, BlendMode.srcIn),
    );
  });

  group('the dark palette stays readable', () {
    const dark = AppPalette.dark;

    test('main text on every background meets WCAG AAA (7:1)', () {
      for (final background in [
        dark.background,
        dark.surface,
        dark.scaffoldBackground,
      ]) {
        expect(contrast(dark.onSurface, background), greaterThanOrEqualTo(7));
      }
    });

    test('secondary text and hints meet WCAG AA (4.5:1) on surfaces', () {
      for (final text in [dark.grey600, dark.grey700, dark.grey500]) {
        expect(contrast(text, dark.surface), greaterThanOrEqualTo(4.5));
      }
      expect(contrast(dark.hintText, dark.surface), greaterThanOrEqualTo(3));
    });

    test('status colours stand out from surfaces (3:1)', () {
      expect(contrast(dark.success, dark.surface), greaterThanOrEqualTo(3));
      expect(contrast(dark.failure, dark.surface), greaterThanOrEqualTo(3));
    });
  });
}

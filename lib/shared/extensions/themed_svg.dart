import 'package:flutter/widgets.dart';
import 'package:paypadi/app/theme.dart';
import 'package:paypadi/gen/assets.gen.dart';

extension ThemedSvg on SvgGenImage {
  /// A one-colour icon painted in [color], or the theme's text colour, so it
  /// stays visible in dark mode. Multi-colour icons (flags, file badges)
  /// should keep using [svg].
  Widget themed(
    BuildContext context, {
    Color? color,
    double? width,
    double? height,
  }) => svg(
    width: width,
    height: height,
    colorFilter: ColorFilter.mode(
      color ?? context.palette.onSurface,
      BlendMode.srcIn,
    ),
  );
}

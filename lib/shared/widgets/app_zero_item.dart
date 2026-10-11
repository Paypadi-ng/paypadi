import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/gen/colors.gen.dart';

class AppZeroItem extends StatelessWidget {
  const AppZeroItem({
    required this.message,
    super.key,
    this.icon,
    this.topPaddingScaleFactor = .5,
  });

  final IconData? icon;
  final String message;
  final double topPaddingScaleFactor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        (context.screenHeight * topPaddingScaleFactor).verticalSpace,
        Row(
          spacing: Values.v12,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: Values.v32,
              color: AppColors.grey600,
            ),
            Text(
              message,
              style: context.textTheme.titleLarge?.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

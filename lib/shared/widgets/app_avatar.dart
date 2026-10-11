import 'package:flutter/material.dart';
import 'package:paypadi/gen/colors.gen.dart';
import 'package:paypadi/shared/widgets/app_network_image.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.radius, this.imageUrl});
  final double? radius;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl case final url?) {
      return AppNetworkImage(url: url, size: radius ?? 40);
    }
    return AnimatedContainer(
      width: radius,
      height: radius,
      duration: kThemeChangeDuration,
      decoration: const BoxDecoration(
        color: AppColors.disabled,
        shape: BoxShape.circle,
      ),
    );
  }
}

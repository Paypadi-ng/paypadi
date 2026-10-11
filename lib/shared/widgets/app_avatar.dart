import 'package:flutter/material.dart';
import 'package:paypadi/gen/colors.gen.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.radius, this.imageUrl});
  final double? radius;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: radius,
      height: radius,
      duration: kThemeChangeDuration,
      decoration: BoxDecoration(
        color: imageUrl != null ? Colors.transparent : AppColors.disabled,
        shape: BoxShape.circle,
        image: imageUrl == null
            ? null
            : DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(imageUrl!),
              ),
      ),
    );
  }
}

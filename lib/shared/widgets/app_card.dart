import 'package:flutter/material.dart';
import 'package:paypadi/app/theme.dart';
import 'package:paypadi/core/utils/extensions.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding,
    this.cardColor,
  });

  final Widget child;
  final Color? cardColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.screenWidth,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor ?? context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 2,
            offset: const Offset(0, 0.05),
            color: context.palette.boxShadow.withValues(alpha: .25),
          ),
        ],
      ),
      child: child,
    );
  }
}

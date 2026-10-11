import 'package:flutter/material.dart';
import 'package:paypadi/gen/colors.gen.dart';

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

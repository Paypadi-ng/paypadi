import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/helpers.dart';
import 'package:paypadi/gen/colors.gen.dart';

class AmountDisplay extends HookWidget {
  const AmountDisplay({required this.controller, super.key});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final controllerListenable = useValueListenable(controller);

    return Column(
      spacing: Values.v12,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: Values.v12),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.amountDisplayBorderColor),
            borderRadius: BorderRadius.circular(Values.v8.r),
          ),
          child: Center(
            child: Text(
              '₦${formatAmount(controllerListenable.text)}',
              style: context.textTheme.headlineLarge,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (PickedAmount amount in PickedAmount.values)
              GestureDetector(
                onTap: () => controller.text = amount.value,
                child: Container(
                  margin: const EdgeInsets.only(right: Values.v10),
                  padding: const EdgeInsets.all(Values.v10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(
                      color: AppColors.amountDisplayBorderColor,
                    ),
                    borderRadius: BorderRadius.circular(Values.v12.r),
                  ),
                  child: Text(
                    '₦${amount.value}',
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

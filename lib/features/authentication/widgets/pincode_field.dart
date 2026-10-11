import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart' show appPrimaryColorProvider;
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/validators.dart';
import 'package:paypadi/gen/colors.gen.dart';
import 'package:pin_code_text_field/pin_code_text_field.dart'
    show PinCodeTextField;

class PinCodeField extends ConsumerWidget {
  const PinCodeField({required this.controller, super.key});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormField<String>(
      validator: (value) => pinCodeValidator(controller.text),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PinCodeTextField(
              autofocus: true,
              controller: controller,
              maxLength: Values.v6.toInt(),
              pinBoxWidth: Values.v48,
              pinBoxHeight: Values.v48,
              pinBoxRadius: Values.v12,
              pinBoxBorderWidth: Values.v1,
              pinBoxOuterPadding: const EdgeInsets.only(right: Values.v4),
              hasTextBorderColor: ref.watch(appPrimaryColorProvider),
              defaultBorderColor: field.hasError
                  ? AppColors.failure
                  : AppColors.unfocusedTextField,
              pinTextStyle: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w400,
              ),
              onTextChanged: (value) => field.didChange(value),
            ),
            if (field.hasError) ...[
              Values.v8.verticalSpace,
              Text(
                field.errorText!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show ConsumerWidget, WidgetRef;
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/gen/assets.gen.dart';
import 'package:paypadi/gen/colors.gen.dart';
import 'package:paypadi/gen/fonts.gen.dart';

class AppTextformfield extends StatelessWidget {
  const AppTextformfield({
    required this.title,
    required this.controller,
    super.key,
    this.hint,
    this.isEnabled,
    this.titleStyle,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  final String title;
  final String? hint;
  final bool? isEnabled;
  final TextStyle? titleStyle;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              titleStyle ??
              context.textTheme.bodyLarge?.copyWith(letterSpacing: 0),
        ),
        Values.v6.verticalSpace,
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          enabled: isEnabled,
          decoration: InputDecoration(hintText: hint),
        ),
        Values.v12.verticalSpace,
      ],
    );
  }
}

class PhoneTextField extends ConsumerWidget {
  const PhoneTextField({
    required this.controller,
    super.key,
    this.validator,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(appPrimaryColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: context.textTheme.titleMedium?.copyWith(
            letterSpacing: Values.zero,
            fontFamily: FontFamily.manrope,
          ),
        ),
        Values.v6.verticalSpace,
        Row(
          spacing: Values.v6,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Values.v16,
                vertical: Values.v14,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.unfocusedTextField),
                borderRadius: BorderRadius.circular(Values.v18),
              ),
              child: Row(
                spacing: Values.v8,
                children: [
                  AppAssets.icons.icNgFlag.svg(),
                  Text(
                    '+234',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.hintText,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                validator: validator,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Values.v16,
                    vertical: Values.v8,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color),
                    borderRadius: BorderRadius.circular(Values.v18),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Values.v18),
                    borderSide: const BorderSide(color: AppColors.failure),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Values.v18),
                    borderSide: const BorderSide(color: AppColors.failure),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Values.v18),
                    borderSide: const BorderSide(
                      color: AppColors.unfocusedTextField,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Values.v12.verticalSpace,
      ],
    );
  }
}

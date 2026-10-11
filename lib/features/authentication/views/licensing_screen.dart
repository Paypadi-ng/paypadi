import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/core/utils/constants.dart' show Values;
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/helpers.dart';
import 'package:paypadi/core/utils/validators.dart';
import 'package:paypadi/gen/colors.gen.dart';
import 'package:paypadi/shared/controllers/user_profile_controller.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
import 'package:paypadi/shared/widgets/app_scaffold.dart';
import 'package:paypadi/shared/widgets/app_textformfield.dart';

@RoutePage()
class LicensingScreen extends HookConsumerWidget {
  const LicensingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverLicense = useTextEditingController();
    final expiryDate = useState<String>('');
    final formRef = useRef(GlobalKey<FormState>());

    ref.listen(driverProfileProvider, (previous, current) {
      current.when(
        data: (d) {
          ref.dismissLoading();
          driverLicense.clear();
          expiryDate.value = '';
        },
        error: (e, st) {
          ref.dismissLoading();
          ref.showExceptionMessage(e, st);
        },
        loading: ref.showLoading,
      );
    });

    return AppScaffold(
      makeScrollable: true,
      appBar: AppBar(
        title: Text(
          'Step 3 out of 5',
          style: context.textTheme.titleSmall,
        ),
        centerTitle: true,
      ),
      child: Form(
        key: formRef.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Values.v32.verticalSpace,
            Text(
              'Licensing',
              style: context.textTheme.headlineMedium,
            ),
            Values.v16.verticalSpace,
            Text(
              'Kindly provide the details below to help give you the best experience.',
              style: context.textTheme.bodyMedium,
            ),
            Values.v32.verticalSpace,
            AppTextformfield(
              title: "Driver's License",
              hint: "Enter your driver's license number",
              controller: driverLicense,
            ),
            _ExpiryDateWidget(date: (date) => expiryDate.value = date),
            Values.v24.verticalSpace,
            FilledButton(
              onPressed: () => submit(
                ref,
                expiryDate.value,
                driverLicense.text,
                formRef.value,
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  void submit(
    WidgetRef ref,
    String expiryDate,
    String driverLicense,
    GlobalKey<FormState> form,
  ) {
    if (!(form.currentState?.validate() ?? false)) return;

    ref.closeKeyboard();

    ref.read(profilePayloadProvider)
      ..['driver_license_number'] = driverLicense
      ..['driver_license_expiry'] = expiryDate;

    unawaited(ref.read(driverProfileProvider.notifier).updateDriverProfile());
  }
}

class _ExpiryDateWidget extends HookConsumerWidget {
  const _ExpiryDateWidget({required this.date});
  final ValueSetter<String> date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = useState<DateTime>(DateTime.now());
    final hasFocus = useState<bool>(false);
    final primaryColor = ref.watch(appPrimaryColorProvider);

    return GestureDetector(
      onTap: () async {
        hasFocus.value = true;
        final pickedDate = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime(2040),
        );

        if (pickedDate == null) return;
        selectedDate.value = pickedDate;
        date(formatDate(pickedDate));
        hasFocus.value = false;
      },
      child: FormField<String>(
        initialValue: formatDate(selectedDate.value),
        validator: dateValidator,
        builder: (field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expiry Date ',
                style: context.textTheme.bodyLarge?.copyWith(
                  letterSpacing: Values.zero,
                ),
              ),
              Values.v6.verticalSpace,
              Container(
                width: context.screenWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: Values.v16,
                  vertical: Values.v14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Values.v12),
                  border: Border.all(
                    color: hasFocus.value
                        ? primaryColor
                        : AppColors.unfocusedTextField,
                  ),
                ),
                child: Text(
                  formatDate(selectedDate.value),
                  style: context.textTheme.bodyMedium,
                ),
              ),
              Values.v12.verticalSpace,
            ],
          );
        },
      ),
    );
  }
}

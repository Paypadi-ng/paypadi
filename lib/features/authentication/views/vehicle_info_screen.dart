import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/core/utils/constants.dart' show Values;
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/shared/controllers/user_profile_controller.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
import 'package:paypadi/shared/widgets/app_scaffold.dart';
import 'package:paypadi/shared/widgets/app_textformfield.dart';

@RoutePage()
class VehicleInformationScreen extends HookConsumerWidget {
  const VehicleInformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carMake = useTextEditingController();
    final carModel = useTextEditingController();
    final productionYear = useTextEditingController();
    final licensePlate = useTextEditingController();
    final formRef = useRef(GlobalKey<FormState>());

    ref.listen(driverProfileProvider, (previous, current) {
      current.when(
        data: (d) {
          ref.dismissLoading();
          carMake.clear();
          carModel.clear();
          productionYear.clear();
          licensePlate.clear();
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
          'Step 2 out of 5',
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
              'Vehicle Information',
              style: context.textTheme.headlineMedium,
            ),
            Values.v16.verticalSpace,
            Text(
              'Kindly provide the details below to help give you the best experience.',
              style: context.textTheme.bodyMedium,
            ),
            Values.v32.verticalSpace,
            AppTextformfield(
              title: 'Car Make',
              hint: 'Enter your car make',
              controller: carMake,
            ),
            AppTextformfield(
              title: 'Car Model',
              hint: 'Enter your car model',
              controller: carModel,
            ),
            AppTextformfield(
              title: 'Year of Production',
              hint: "Enter your car's year of production",
              keyboardType: TextInputType.number,
              controller: productionYear,
            ),
            AppTextformfield(
              title: 'License Plate',
              hint: 'Enter your license plate',
              controller: licensePlate,
            ),
            Values.v24.verticalSpace,
            FilledButton(
              onPressed: () => submit(
                ref,
                carMake.text,
                carModel.text,
                productionYear.text,
                licensePlate.text,
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
    String carMake,
    String carModel,
    String productionYear,
    String licensePlate,
    GlobalKey<FormState> form,
  ) {
    if (!(form.currentState?.validate() ?? false)) return;

    ref.closeKeyboard();

    ref.read(profilePayloadProvider)
      ..['vehicle_make'] = carMake
      ..['vehicle_model'] = carModel
      ..['vehicle_year'] = productionYear
      ..['license_plate'] = licensePlate;

    unawaited(ref.read(driverProfileProvider.notifier).createProfile());
  }
}

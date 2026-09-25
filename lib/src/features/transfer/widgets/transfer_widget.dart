import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/gen/colors.gen.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/shared/controllers/user_profile/user_profile_controller.dart';
import 'package:paypadi/src/shared/widgets/app_textformfield.dart';
import 'package:paypadi/src/shared/widgets/banks_list.dart';

class RecipientInformation extends ConsumerWidget {
  const RecipientInformation({
    required this.recipientNumberController,
    super.key,
  });
  final TextEditingController recipientNumberController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);

    return switch (user.value?.role) {
      .rider => _RiderRecipient(controller: recipientNumberController),
      .driver => _DriverRecipient(controller: recipientNumberController),
      _ => const SizedBox.shrink(),
    };
  }
}

class _RiderRecipient extends ConsumerWidget {
  const _RiderRecipient({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppTextformfield(
      title: 'Account Number',
      hint: 'Enter 10-digit Account number or Phone Number',
      controller: controller,
      keyboardType: TextInputType.number,
    );
  }
}

class _DriverRecipient extends HookConsumerWidget {
  const _DriverRecipient({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWithdrawing = useState<bool>(false);
    final bankController = useTextEditingController();

    return Column(
      children: [
        _SelectTransferType(isWithdrawing: isWithdrawing),
        Values.v16.verticalSpace,
        AppTextformfield(
          title: 'Account Number',
          hint: 'Enter 10-digit Account number or Phone Number',
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        Values.v16.verticalSpace,
        AnimatedSwitcher(
          duration: Durations.short4,
          reverseDuration: Durations.short4,
          switchInCurve: Curves.easeInExpo,
          switchOutCurve: Curves.easeOutExpo,
          child: isWithdrawing.value
              ? BanksList(
                  controller: bankController,
                  onBankSelected: (bank) {},
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SelectTransferType extends ConsumerWidget {
  const _SelectTransferType({required this.isWithdrawing});
  final ValueNotifier<bool> isWithdrawing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(appPrimaryColorProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.disabled,
        borderRadius: BorderRadius.circular(Values.v36),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          GestureDetector(
            onTap: () => isWithdrawing.value = false,
            child: AnimatedContainer(
              duration: Durations.short4,
              padding: const EdgeInsets.symmetric(
                vertical: Values.v6,
                horizontal: Values.v24,
              ),
              decoration: BoxDecoration(
                color: !isWithdrawing.value ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(Values.v36),
              ),
              child: Text(
                'To Paypadi',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: !isWithdrawing.value
                      ? AppColors.white
                      : AppColors.black,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => isWithdrawing.value = true,
            child: AnimatedContainer(
              duration: Durations.short4,
              padding: const EdgeInsets.symmetric(
                vertical: Values.v6,
                horizontal: Values.v24,
              ),
              decoration: BoxDecoration(
                color: isWithdrawing.value ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(Values.v36),
              ),
              child: Text(
                'To Other Banks',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: isWithdrawing.value
                      ? AppColors.white
                      : AppColors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

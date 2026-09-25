import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/core/models/bank_model/bank_model.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/features/authentication/controller/bank_account_controller.dart';

class BanksList extends ConsumerWidget {
  const BanksList({
    required this.controller,
    required this.onBankSelected,
    super.key,
  });

  final TextEditingController controller;
  final ValueSetter<BankModel> onBankSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banks = ref.watch(bankListControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bank Name',
          style: context.textTheme.bodyLarge?.copyWith(letterSpacing: 0),
        ),
        Values.v6.verticalSpace,
        DropdownMenu<BankModel>(
          enableFilter: true,
          requestFocusOnTap: true,
          hintText: 'Select Bank',
          controller: controller,
          width: context.screenWidth,
          menuHeight: context.screenHeight * .4,
          trailingIcon: const Icon(Icons.arrow_drop_down),
          selectedTrailingIcon: const SizedBox.shrink(),
          onSelected: (bank) {
            if (bank == null) return;
            onBankSelected(bank);
          },
          dropdownMenuEntries: [
            for (BankModel bank in banks.value ?? <BankModel>[])
              DropdownMenuEntry<BankModel>(
                value: bank,
                label: bank.name,
              ),
          ],
        ),
        Values.v12.verticalSpace,
      ],
    );
  }
}

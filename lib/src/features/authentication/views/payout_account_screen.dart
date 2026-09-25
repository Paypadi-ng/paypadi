import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:paypadi/core/models/bank_model/bank_model.dart';
import 'package:paypadi/core/utils/constants.dart' show Values;
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/validators.dart';
import 'package:paypadi/src/features/authentication/controller/bank_account_controller.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';
import 'package:paypadi/src/shared/widgets/app_textformfield.dart';
import 'package:paypadi/src/shared/widgets/banks_list.dart';

@RoutePage()
class PayoutAccountScreen extends HookConsumerWidget {
  const PayoutAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formRef = useRef(GlobalKey<FormState>());
    final selectedBank = useState<BankModel?>(null);
    final showSubmit = useState<bool>(false);
    final bankController = useTextEditingController();
    final accountName = useTextEditingController();
    final accountNumber = useTextEditingController();

    ref.listen(verifiedBankAccountProvider, (previous, current) {
      current.when(
        data: (d) {
          ref.dismissLoading();
          accountName.text = d?.accountName ?? '';
          if (d != null) showSubmit.value = true;
        },
        error: (e, st) => ref.dismissLoading(),
        loading: ref.showLoading,
      );
    });

    ref.listen(bankListControllerProvider, (_, state) {
      state.when(
        data: (d) => ref.dismissLoading(),
        error: (e, st) => ref.dismissLoading(),
        loading: () => ref.showLoading(),
      );
    });

    ref.listen(payoutAccountProvider, (_, state) {
      state.when(
        data: (d) => ref.dismissLoading(),
        error: (e, st) => ref.dismissLoading(),
        loading: () => ref.showLoading(),
      );
    });

    return AppScaffold(
      makeScrollable: true,
      child: Form(
        key: formRef.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Values.v32.verticalSpace,
            Text(
              'Add your payout account',
              style: context.textTheme.headlineMedium,
            ),
            Values.v16.verticalSpace,
            Text(
              "We'll send your earnings directly to this account.",
              style: context.textTheme.bodyMedium,
            ),
            Values.v32.verticalSpace,
            BanksList(
              controller: bankController,
              onBankSelected: (bank) {
                selectedBank.value = bank;
                showSubmit.value = false;
                accountName.clear();
              },
            ),
            AppTextformfield(
              title: 'Account Number',
              hint: 'Enter account number',
              controller: accountNumber,
              keyboardType: TextInputType.number,
              validator: accountNumberValidator,
            ),
            AppTextformfield(
              isEnabled: false,
              title: 'Account Name',
              hint: 'Account Name',
              controller: accountName,
            ),
            Values.v24.verticalSpace,
            FilledButton(
              onPressed: !showSubmit.value
                  ? () {
                      _verifyAccountInfo(
                        ref,
                        selectedBank.value?.code ?? '',
                        accountNumber.text,
                        formRef.value,
                      );
                    }
                  : () {
                      showSubmit.value = false;
                      _navigateNext(
                        ref,
                        selectedBank.value?.code ?? '',
                        selectedBank.value?.name ?? '',
                        accountName.text,
                        accountNumber.text,
                      );
                    },
              child: Text(!showSubmit.value ? 'Confirm' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyAccountInfo(
    WidgetRef ref,
    String bankCode,
    String accountNumber,
    GlobalKey<FormState> form,
  ) {
    final isFormValid = form.currentState?.validate() ?? false;

    if (!isFormValid || bankCode.isEmpty) {
      if (bankCode.isEmpty) ref.showErrorToast('Please select a bank.');
      return;
    }
    unawaited(
      ref.read(verifiedBankAccountProvider.notifier).verifyBankInformation({
        'account_number': accountNumber,
        'bank_code': bankCode,
        // 'bank_code': "001",
      }),
    );
  }

  void _navigateNext(
    WidgetRef ref,
    String bankCode,
    String bankName,
    String accountName,
    String accountNumber,
  ) {
    final verified = ref.read(verifiedBankAccountProvider);
    if (!verified.hasValue || verified.value == null) {
      ref.showErrorToast('Please verify your account details first.');
      return;
    }

    final payload = <String, dynamic>{
      'account_type': 'bank_account',
      'account_name': accountName,
      'account_number': accountNumber,
      'bank_name': bankName,
      'bank_code': bankCode,
      'is_primary': true,
    };
    unawaited(
      ref.read(payoutAccountProvider.notifier).createPayoutAccount(payload),
    );
  }
}

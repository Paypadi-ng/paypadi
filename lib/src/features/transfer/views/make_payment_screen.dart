import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/gen/colors.gen.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/models/account_lookup_model/account_lookup_model.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/features/home/controller/wallet_controller.dart';
import 'package:paypadi/src/features/transfer/controller/transaction_controller.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';
import 'package:paypadi/src/shared/widgets/app_textformfield.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class MakePaymentScreen extends HookConsumerWidget {
  const MakePaymentScreen({required this.recipientNumber, super.key});
  final String recipientNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSavedAsBeneficiary = useState<bool>(false);
    final commentController = useTextEditingController();
    final recipientDetails = ref.watch(accountLookupProvider(recipientNumber));

    return AppScaffold(
      title: 'Transfer',
      child: Column(
        children: [
          Values.v16.verticalSpace,
          _BankAccountInformation(
            isLoading: recipientDetails.isLoading,
            recipient: recipientDetails.value,
          ),
          Values.v32.verticalSpace,
          AppTextformfield(
            title: 'Comments',
            hint: 'Enter a narration',
            controller: commentController,
            titleStyle: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
              letterSpacing: kZeroLetterSpacing,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Values.v14),
                child: Text(
                  'Save as Beneficiary',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Switch.adaptive(
                value: hasSavedAsBeneficiary.value,
                onChanged: recipientDetails.isLoading
                    ? null
                    : (value) {
                        hasSavedAsBeneficiary.value = true;
                        unawaited(
                          ref
                              .read(walletControllerProvider.notifier)
                              .saveBeneficiary(recipientDetails.value!),
                        );
                      },
              ),
            ],
          ),
          Values.v48.verticalSpace,
          FilledButton(
            onPressed: recipientDetails.value == null
                ? null
                : () => continueToPinPage(
                    ref,
                    commentController.text,
                    recipientDetails.value!,
                  ),
            child: const Text('Make Payment'),
          ),
        ],
      ),
    );
  }

  void continueToPinPage(
    WidgetRef ref,
    String desc,
    AccountLookupModel recipient,
  ) {
    ref.read(transactionPayloadProvider)
      ..['description'] = desc
      ..['recipient_account_number'] = recipient.accountNumber
      ..['recipient_bank_code'] = recipient.bankCode;

    unawaited(ref.read(appRouterProvider).push(const EnterPinRoute()));
  }
}

class _BankAccountInformation extends StatelessWidget {
  const _BankAccountInformation({
    required this.isLoading,
    required this.recipient,
  });

  final bool isLoading;
  final AccountLookupModel? recipient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Values.v12,
        vertical: Values.v10,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.bankBorderColor),
        borderRadius: BorderRadius.circular(Values.v48),
      ),
      child: Row(
        spacing: Values.v20,
        children: [
          Skeletonizer(
            enabled: isLoading,
            child: Container(
              width: Values.v64,
              height: Values.v64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Values.v24),
                image: DecorationImage(
                  image: NetworkImage(
                    recipient?.profilePicUrl ?? kDemoProfilePic,
                  ),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeletonizer(
                  enabled: isLoading,
                  child: Text(
                    isLoading
                        ? 'FirstName LastName'
                        : '${recipient?.firstName} ${recipient?.lastName}',
                    style: context.textTheme.titleLarge,
                  ),
                ),
                Skeletonizer(
                  enabled: isLoading,
                  child: Text(
                    isLoading ? 'AccountNumber' : '${recipient?.accountNumber}',
                    style: context.textTheme.titleSmall?.copyWith(
                      letterSpacing: kZeroLetterSpacing,
                      color: AppColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/gen/colors.gen.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/helpers.dart';
import 'package:paypadi/src/features/transfer/controller/transaction_controller.dart';
import 'package:paypadi/src/features/transfer/widgets/dotted_line.dart';
import 'package:paypadi/src/features/transfer/widgets/payment_details.dart';
import 'package:paypadi/src/features/transfer/widgets/receipt_card.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class ConfirmPaymentScreen extends ConsumerWidget {
  const ConfirmPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentSummary = ref.watch(initiatePaymentControllerProvider);
    final isTransferring = ref.watch(transactionControllerProvider).isLoading;

    ref.listen(transactionControllerProvider, (previous, current) {
      current.when(
        data: (d) => ref.dismissLoading(),
        error: (e, st) => ref.dismissLoading(),
        loading: () => ref.showLoading(),
      );
    });

    return AppScaffold(
      title: 'Confirm Payment',
      bgColor: AppColors.scaffoldBackground,
      child: Column(
        children: [
          Values.v16.verticalSpace,
          ReceiptCard(
            child: Column(
              children: [
                Text(
                  'Payment Summary!',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    letterSpacing: kZeroLetterSpacing,
                  ),
                ),
                Values.v8.verticalSpace,
                Skeletonizer(
                  enabled: paymentSummary.isLoading,
                  child: Text(
                    paymentSummary.isLoading
                        ? placeholder
                        : '₦ ${formatAmount(paymentSummary.value?.amount)}',
                    style: context.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: kZeroLetterSpacing,
                    ),
                  ),
                ),
                Values.v32.verticalSpace,
                const Divider(
                  indent: Values.v8,
                  endIndent: Values.v8,
                  color: AppColors.dividerColor,
                ),
                Values.v32.verticalSpace,
                PaymentDetails(
                  detail: 'Ref Number',
                  isLoading: paymentSummary.isLoading,
                  value: paymentSummary.value?.reference,
                ),
                PaymentDetails(
                  detail: 'Payment time',
                  isLoading: paymentSummary.isLoading,
                  value: paymentSummary.isLoading
                      ? placeholderShort
                      : getTransactionDate(paymentSummary.value?.createdAt),
                ),
                PaymentDetails(
                  detail: 'Payment',
                  isLoading: paymentSummary.isLoading,
                  value: paymentSummary.isLoading
                      ? placeholder
                      : capitalizeFirstChar(
                          paymentSummary.value?.paymentType.name,
                        ),
                ),
                const DottedDivider(topPadding: Values.v2),
                PaymentDetails(
                  detail: 'Amount',
                  isLoading: paymentSummary.isLoading,
                  value: paymentSummary.isLoading
                      ? placeholder
                      : '₦ ${formatAmount(paymentSummary.value?.amount)}',
                ),
              ],
            ),
          ),
          Spacer(flex: Values.v4.toInt()),
          FilledButton(
            style: ButtonStyle(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(Values.v48),
                ),
              ),
            ),
            onPressed: isTransferring
                ? null
                : () => ref
                      .read(transactionControllerProvider.notifier)
                      .transfer(),
            child: const Text('Make Payment'),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

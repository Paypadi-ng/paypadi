import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/gen/assets.gen.dart';
import 'package:paypadi/config/gen/colors.gen.dart' show AppColors;
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/helpers.dart';
import 'package:paypadi/src/features/transfer/controller/receipt_controller.dart';
import 'package:paypadi/src/features/transfer/widgets/dotted_line.dart';
import 'package:paypadi/src/features/transfer/widgets/payment_details.dart';
import 'package:paypadi/src/features/transfer/widgets/receipt_card.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';
import 'package:screenshot/screenshot.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({required this.referenceId, super.key});
  final String referenceId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  final _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final pixelRatio = context.devicePixelRatio;
    final color = ref.watch(appPrimaryColorProvider);
    final receipt = ref.watch(receiptControllerProvider(widget.referenceId));

    return AppScaffold(
      showAppBar: false,
      bgColor: AppColors.scaffoldBackground,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CloseButton(
                onPressed: () => ref
                    .read(appRouterProvider)
                    .popUntilRouteWithName(HomeRoute.name),
              ),
              IconButton(
                onPressed: () async => ref
                    .read(receiptServiceProvider)
                    .shareReceipt(pixelRatio, _screenshotController),
                icon: AppAssets.icons.icShare.svg(),
              ),
            ],
          ),
          Values.v16.verticalSpace,
          Screenshot(
            controller: _screenshotController,
            child: ReceiptCard(
              child: Column(
                children: [
                  _PaymentDetailsStatusIcon(status: receipt.value?.status),
                  Values.v16.verticalSpace,
                  Skeletonizer(
                    enabled: receipt.isLoading,
                    child: Text(
                      receipt.isLoading
                          ? placeholder
                          : 'Payment ${capitalizeFirstChar(receipt.value?.status.name)}',
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: kZeroLetterSpacing,
                      ),
                    ),
                  ),
                  Values.v8.verticalSpace,
                  Skeletonizer(
                    enabled: receipt.isLoading,
                    child: Text(
                      receipt.isLoading
                          ? placeholder
                          : '₦ ${formatAmount(receipt.value?.amount)}',
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
                    isLoading: receipt.isLoading,
                    value: receipt.value?.reference,
                  ),
                  PaymentDetails(
                    detail: 'Payment Time',
                    isLoading: receipt.isLoading,
                    value: receipt.isLoading
                        ? placeholderShort
                        : getTransactionDate(receipt.value?.createdAt),
                  ),
                  PaymentDetails(
                    detail: 'Payment Method',
                    isLoading: receipt.isLoading,
                    value: receipt.isLoading
                        ? placeholderShort
                        : capitalizeFirstChar(receipt.value?.type.name),
                  ),
                  PaymentDetails(
                    detail: 'Sender Name',
                    isLoading: receipt.isLoading,
                    value: receipt.value?.senderName,
                  ),
                  PaymentDetails(
                    detail: 'Receiver Name',
                    isLoading: receipt.isLoading,
                    value: receipt.value?.recipientName,
                  ),
                  const DottedDivider(topPadding: Values.v2),
                  PaymentDetails(
                    detail: 'Amount',
                    isLoading: receipt.isLoading,
                    value: receipt.isLoading
                        ? placeholderShort
                        : '₦ ${formatAmount(receipt.value?.amount)}',
                  ),
                  PaymentDetails(
                    detail: 'Transaction Fee',
                    isLoading: receipt.isLoading,
                    value: receipt.isLoading
                        ? placeholderShort
                        : '₦ ${formatAmount(receipt.value?.transactionFee)}',
                  ),
                ],
              ),
            ),
          ),

          const Spacer(flex: 3),
          OutlinedButton.icon(
            onPressed: () async => ref
                .read(receiptServiceProvider)
                .generateReceiptInPdf(_screenshotController, pixelRatio),
            label: const Text('Get PDF Receipt'),
            icon: AppAssets.icons.icDownload.svg(color: color),
          ),
          Values.v12.verticalSpace,
          FilledButton(
            onPressed: () => ref
                .read(appRouterProvider)
                .popUntilRouteWithName(HomeRoute.name),
            child: const Text('Back to Home'),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PaymentDetailsStatusIcon extends HookWidget {
  const _PaymentDetailsStatusIcon({required this.status});
  final TransactionStatus? status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Values.v72,
      height: Values.v72,
      padding: const EdgeInsets.all(Values.v24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (status) {
          TransactionStatus.success || TransactionStatus.completed =>
            AppColors.success.withValues(alpha: .12),
          TransactionStatus.failure => AppColors.failure.withValues(alpha: .12),
          TransactionStatus.pending => Colors.amber.withValues(alpha: .12),
          null => AppColors.disabled.withValues(alpha: .12),
        },
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: switch (status) {
            TransactionStatus.success ||
            TransactionStatus.completed => AppColors.success,
            TransactionStatus.failure => AppColors.failure,
            TransactionStatus.pending => Colors.amber,
            null => AppColors.disabled,
          },
        ),
        child: Icon(
          switch (status) {
            TransactionStatus.success ||
            TransactionStatus.completed => Icons.check,
            TransactionStatus.failure => Icons.close,
            TransactionStatus.pending => Icons.pending,
            null => Icons.question_mark,
          },
          color: AppColors.white,
        ),
      ),
    );
  }
}

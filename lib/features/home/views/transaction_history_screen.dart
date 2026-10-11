import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/helpers.dart';
import 'package:paypadi/data/transaction/models/transaction_model.dart';
import 'package:paypadi/features/home/controllers/wallet_controller.dart';
import 'package:paypadi/gen/colors.gen.dart';
import 'package:paypadi/shared/placeholder_data.dart';
import 'package:paypadi/shared/widgets/app_scaffold.dart';
import 'package:paypadi/shared/widgets/app_zero_item.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionHistory = ref.watch(historyControllerProvider);
    final history = transactionHistory.value;
    final transactions = transactionHistory.isLoading
        ? kMockTransactionHistory
        : history?.items ?? const <TransactionHistoryModel>[];

    return AppScaffold(
      onRefresh: () => Future(
        () => ref.invalidate(historyControllerProvider),
      ),
      showAppBar: false,
      // leftPadding: Values.zero,
      // rightPadding: Values.zero,
      makeScrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transactions',
            style: context.textTheme.titleMedium,
          ),
          if (transactionHistory.value?.items.isEmpty ?? false)
            const AppZeroItem(
              topPaddingScaleFactor: .4,
              icon: Icons.receipt_long_outlined,
              message: 'No Recent Transaction',
            )
          else ...[
            // The page already scrolls, so lay the tiles out in it rather
            // than in a fixed-height list that clipped everything past the
            // first screenful.
            Values.v16.verticalSpace,
            for (final transaction in transactions)
              _TransactionTile(
                isLoading: transactionHistory.isLoading,
                transaction: transaction,
                onTap: () => ref
                    .read(appRouterProvider)
                    .push(ReceiptRoute(referenceId: transaction.reference)),
              ),
            if (history?.hasMore ?? false)
              Center(
                child: history?.isLoadingMore ?? false
                    ? const Padding(
                        padding: EdgeInsets.all(Values.v12),
                        child: CircularProgressIndicator.adaptive(),
                      )
                    : TextButton(
                        onPressed: () => ref
                            .read(historyControllerProvider.notifier)
                            .loadMore(),
                        child: const Text('Show more'),
                      ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({
    required this.isLoading,
    required this.transaction,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;
  final TransactionHistoryModel transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(appPrimaryColorProvider);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Values.v8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeletonizer(
              enabled: isLoading,
              child: Container(
                width: Values.v48,
                height: Values.v48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(Values.v16),
                ),
                child: isLoading
                    ? Icon(Icons.question_mark, color: color)
                    : Icon(
                        switch (transaction.type.isCredit) {
                          true => Icons.arrow_downward,
                          false => Icons.arrow_upward,
                          null => Icons.question_mark,
                        },
                        color: color,
                      ),
              ),
            ),
            Values.v12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeletonizer(
                    enabled: isLoading,
                    child: Text(
                      'Transfer ${getTransactionDirectionLabel(transaction.type)} ${name(transaction.type)}',
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Skeletonizer(
                    enabled: isLoading,
                    child: Text(
                      getTransactionDate(transaction.createdAt),
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.grey500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Values.v12.horizontalSpace,
            Skeletonizer(
              enabled: isLoading,
              child: Text(
                '${amountSign(transaction.type)}₦ ${formatAmount(transaction.amount)}',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: transactionColor(transaction.type),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String name(TransactionType type) {
    return switch (type.isCredit) {
      true => transaction.senderName,
      false => transaction.recipientName,
      null => '?',
    };
  }

  String amountSign(TransactionType type) {
    return switch (type.isCredit) {
      true => '+',
      false => '-',
      null => '?',
    };
  }

  Color transactionColor(TransactionType type) {
    return switch (type.isCredit) {
      true => AppColors.success,
      false => AppColors.failure,
      null => AppColors.disabled,
    };
  }
}

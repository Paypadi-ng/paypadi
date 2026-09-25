import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/gen/assets.gen.dart';
import 'package:paypadi/config/gen/colors.gen.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/helpers.dart' show formatAmount;
import 'package:paypadi/src/features/home/controller/wallet_controller.dart';
import 'package:paypadi/src/shared/widgets/app_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UserWallet extends StatelessWidget {
  const UserWallet({required this.type, super.key});
  final AccountType type;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      .rider => const _RiderWallet(),
      .driver => const _DriverWallet(),
      .unknown => const Text('Refresh this page'),
    };
  }
}

class _RiderWallet extends HookConsumerWidget {
  const _RiderWallet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideBalance = useState<bool>(true);
    final wallet = ref.watch(walletControllerProvider);

    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: Values.v8,
                children: [
                  Text(
                    'Available Balance',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.walletCardTextColor,
                    ),
                  ),
                  InkWell(
                    onTap: () => hideBalance.value = !hideBalance.value,
                    child: Padding(
                      padding: const EdgeInsets.all(Values.v4),
                      child: Icon(
                        hideBalance.value
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        color: AppColors.walletCardIconColor,
                      ),
                    ),
                  ),
                ],
              ),
              Skeletonizer(
                enabled: wallet.isLoading,
                child: Text(
                  hideBalance.value
                      ? "${wallet.value?.currency ?? "₦"} ****"
                      : "${wallet.value?.currency ?? "₦"} ${formatAmount(wallet.value?.availableBalance)}",
                  style: context.textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          FilledButton(
            onPressed: () =>
                ref.read(appRouterProvider).push(const DepositMoneyRoute()),
            style: FilledButton.styleFrom(
              fixedSize: kButtonSmallSize,
              foregroundColor: ref.watch(appPrimaryColorProvider),
              backgroundColor: ref.watch(appPrimaryColorProvider).withAlpha(20),
              side: BorderSide(color: ref.watch(appPrimaryColorProvider)),
              textStyle: context.textTheme.bodyMedium?.copyWith(
                letterSpacing: -0.08,
                fontWeight: FontWeight.w600,
                color: ref.watch(appPrimaryColorProvider),
              ),
            ),
            child: const Text('Add Money'),
          ),
        ],
      ),
    );
  }
}

class _DriverWallet extends HookConsumerWidget {
  const _DriverWallet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideBalance = useState<bool>(true);
    final wallet = ref.watch(walletControllerProvider);

    return AppCard(
      child: Column(
        spacing: Values.v6,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: Values.v8,
            children: [
              Text(
                'Available Balance',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.walletCardTextColor,
                ),
              ),
              InkWell(
                onTap: () => hideBalance.value = !hideBalance.value,
                child: Padding(
                  padding: const EdgeInsets.all(Values.v4),
                  child: Icon(
                    hideBalance.value
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    color: AppColors.walletCardIconColor,
                  ),
                ),
              ),
            ],
          ),
          Skeletonizer(
            enabled: wallet.isLoading,
            child: Text(
              hideBalance.value
                  ? "${wallet.value?.currency ?? "₦"} ****"
                  : "${wallet.value?.currency ?? "₦"} ${formatAmount(wallet.value?.availableBalance)}",
              style: context.textTheme.headlineSmall,
            ),
          ),
          Row(
            spacing: Values.v10,
            children: [
              Expanded(
                child: FilledButton.icon(
                  label: const Text('Add Money'),
                  icon: const Icon(Icons.add, color: AppColors.white),
                  style: FilledButton.styleFrom(
                    fixedSize: kButtonSmallSize,
                    foregroundColor: AppColors.white,
                    backgroundColor: ref.watch(appPrimaryColorProvider),
                    textStyle: context.textTheme.bodyMedium?.copyWith(
                      letterSpacing: -0.08,
                      fontWeight: FontWeight.w600,
                      color: ref.watch(appPrimaryColorProvider),
                    ),
                  ),
                  onPressed: () => ref
                      .read(appRouterProvider)
                      .push(const DepositMoneyRoute()),
                ),
              ),
              Expanded(
                child: FilledButton.icon(
                  icon: AppAssets.icons.icWithdraw.svg(),
                  label: const Text('Withdraw'),
                  onPressed: () =>
                      ref.read(appRouterProvider).push(TransferRoute()),
                  style: FilledButton.styleFrom(
                    fixedSize: kButtonSmallSize,
                    foregroundColor: ref.watch(appPrimaryColorProvider),
                    backgroundColor: ref
                        .watch(appPrimaryColorProvider)
                        .withAlpha(20),
                    side: BorderSide(color: ref.watch(appPrimaryColorProvider)),
                    textStyle: context.textTheme.bodyMedium?.copyWith(
                      letterSpacing: -0.08,
                      fontWeight: FontWeight.w600,
                      color: ref.watch(appPrimaryColorProvider),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

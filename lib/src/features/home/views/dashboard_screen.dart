import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:paypadi/config/gen/assets.gen.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/features/home/controller/wallet_controller.dart';
import 'package:paypadi/src/features/home/widgets/amount_display.dart';
import 'package:paypadi/src/features/home/widgets/user_wallets.dart';
import 'package:paypadi/src/features/transfer/controller/transaction_controller.dart';
import 'package:paypadi/src/shared/controllers/user_profile/user_profile_controller.dart';
import 'package:paypadi/src/shared/widgets/app_keypad.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';
import 'package:paypadi/src/shared/widgets/custom_appbar.dart';

@RoutePage()
class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountTextController = useTextEditingController(text: '0');
    final amountValue = useValueListenable(amountTextController);
    final user = ref.watch(userProfileProvider);

    return AppScaffold(
      showAppBar: false,
      appBar: CustomAppbar(name: user.value?.firstName),
      onRefresh: () => Future(
        () => ref.invalidate(walletControllerProvider),
      ),
      makeScrollable: true,
      child: Column(
        children: [
          Values.v32.verticalSpace,
          UserWallet(type: user.value?.role ?? AccountType.unknown),
          Values.v32.verticalSpace,
          AmountDisplay(controller: amountTextController),
          Values.v48.verticalSpace,
          AppKeypad(
            keyLength: 10,
            controller: amountTextController,
          ),
          Values.v36.verticalSpace,
          Row(
            spacing: Values.v12,
            children: [
              Flexible(
                child: FilledButton.icon(
                  onPressed: _canTransfer(amountValue.text)
                      ? () => initializeTransferProcess(ref, amountValue.text)
                      : null,
                  label: const Text('Send Cash'),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward, size: 24),
                  style: context.filledButtonTheme.style?.copyWith(
                    textStyle: WidgetStatePropertyAll(
                      context.textTheme.bodyLarge?.copyWith(
                        letterSpacing: -0.43,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    ref.read(appRouterProvider).push(const QrCodeRoute()),
                child: AppAssets.icons.icQrCode.svg(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void initializeTransferProcess(WidgetRef ref, String amount) {
    final cleanAmount = amount.replaceAll(RegExp(r'[^0-9.]'), '');

    ref.read(transactionPayloadProvider).addAll({'amount': cleanAmount});
    unawaited(ref.read(appRouterProvider).push(TransferRoute()));
  }

  bool _canTransfer(String value) {
    if (value.trim().isEmpty) return false;

    // 1. Strip out commas, spaces, currency symbols, etc.
    // This leaves only numbers and the decimal point.
    final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');

    // 2. Parse the clean, raw number string
    final parsedAmount = num.tryParse(cleanValue);

    // 3. Evaluate
    if (parsedAmount == null) return false;

    return parsedAmount > 0;
  }
}

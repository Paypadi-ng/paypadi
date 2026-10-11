import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/core/api/exceptions/app_exception.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/data/wallet/models/user_bank_account_model.dart';
import 'package:paypadi/features/home/controllers/deposit_account_controller.dart';
import 'package:paypadi/gen/colors.gen.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
import 'package:paypadi/shared/widgets/app_card.dart';
import 'package:paypadi/shared/widgets/app_scaffold.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Shown when the deposit account fails to load with no server message.
const depositAccountUnavailableMessage =
    "We couldn't load your deposit account. Please try again.";

/// The deposit account as copied or shared. It labelled the account
/// holder's name as the bank before.
String depositAccountDetails(UserBankAccountModel account) =>
    'Bank: ${account.bankName}\n'
    'Account Name: ${account.name}\n'
    'Account Number: ${account.number}';

@RoutePage()
class DepositMoneyScreen extends HookConsumerWidget {
  const DepositMoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositAccount = ref.watch(depositAccountControllerProvider);

    // Without this the screen fell back to its skeleton placeholders ("John
    // Doe", "123456789") as if they were the user's account details.
    if (depositAccount case AsyncValue(:final error?, isLoading: false)) {
      return AppScaffold(
        title: 'Add money',
        child: Padding(
          padding: const EdgeInsets.only(top: Values.v32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                error is AppException
                    ? error.message
                    : depositAccountUnavailableMessage,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
              Values.v12.verticalSpace,
              TextButton(
                onPressed: () =>
                    ref.invalidate(depositAccountControllerProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Add money',
      child: Padding(
        padding: const EdgeInsets.only(top: Values.v32),
        child: AppCard(
          padding: const EdgeInsets.all(Values.v16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  letterSpacing: kZeroLetterSpacing,
                  color: AppColors.walletCardTextColor,
                ),
              ),
              Skeletonizer(
                enabled: depositAccount.isLoading,
                child: Text(
                  depositAccount.value?.bankName ?? 'John Doe',
                  style: context.textTheme.bodyLarge?.copyWith(
                    letterSpacing: kZeroLetterSpacing,
                  ),
                ),
              ),

              Values.v16.verticalSpace,
              Text(
                'Account Number',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  letterSpacing: kZeroLetterSpacing,
                  color: AppColors.walletCardTextColor,
                ),
              ),
              Skeletonizer(
                enabled: depositAccount.isLoading,
                child: Text(
                  depositAccount.value?.number ?? '123456789',
                  style: context.textTheme.bodyLarge?.copyWith(
                    letterSpacing: kZeroLetterSpacing,
                  ),
                ),
              ),
              Values.v12.verticalSpace,
              Row(
                spacing: Values.v12,
                children: [
                  FilledButton(
                    onPressed: depositAccount.value == null
                        ? null
                        : () => copyAccountToClipBoard(
                            ref,
                            depositAccount.value!,
                          ),
                    style: context.filledButtonTheme.style?.copyWith(
                      fixedSize: const WidgetStatePropertyAll(
                        kButtonMediumSize,
                      ),
                      foregroundColor: WidgetStatePropertyAll(
                        ref.watch(appPrimaryColorProvider),
                      ),
                      backgroundColor: WidgetStatePropertyAll(
                        ref.watch(appPrimaryColorProvider).withAlpha(20),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          side: BorderSide(
                            color: ref.watch(appPrimaryColorProvider),
                          ),
                          borderRadius: BorderRadiusGeometry.circular(
                            Values.v12,
                          ),
                        ),
                      ),
                      textStyle: WidgetStatePropertyAll(
                        context.textTheme.bodyMedium?.copyWith(
                          letterSpacing: -0.08,
                          color: ref.watch(appPrimaryColorProvider),
                        ),
                      ),
                    ),
                    child: const Text('Copy'),
                  ),
                  Flexible(
                    child: FilledButton(
                      onPressed: depositAccount.value == null
                          ? null
                          : () =>
                                shareAccountInformation(depositAccount.value!),
                      style: context.filledButtonTheme.style?.copyWith(
                        fixedSize: const WidgetStatePropertyAll(
                          kButtonMediumSize,
                        ),
                      ),
                      child: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> copyAccountToClipBoard(
    WidgetRef ref,
    UserBankAccountModel account,
  ) async {
    final String depositAccountInfo = depositAccountDetails(account);

    await Clipboard.setData(
      ClipboardData(text: depositAccountInfo),
    ).then((value) => ref.showSuccessToast('Successfully copied information'));
  }

  Future<void> shareAccountInformation(UserBankAccountModel account) async {
    final String depositAccountInfo = depositAccountDetails(account);

    await SharePlus.instance.share(
      ShareParams(text: depositAccountInfo),
    );
  }
}

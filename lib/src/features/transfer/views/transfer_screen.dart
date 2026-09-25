import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/gen/colors.gen.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/models/beneficiary_model/beneficiary_model.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/helpers.dart';
import 'package:paypadi/src/features/transfer/controller/beneficiaries_controller.dart';
import 'package:paypadi/src/features/transfer/widgets/transfer_widget.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';
import 'package:paypadi/src/shared/widgets/app_zero_item.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class TransferScreen extends HookConsumerWidget {
  const TransferScreen({super.key, this.number});
  final String? number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipientNumber = useTextEditingController(text: number);

    return AppScaffold(
      title: 'Transfer',
      child: SingleChildScrollView(
        child: Column(
          children: [
            Values.v16.verticalSpace,
            RecipientInformation(recipientNumberController: receipientNumber),
            Values.v32.verticalSpace,
            FilledButton(
              onPressed: () => _continue(ref, receipientNumber.text),
              child: const Text('Continue'),
            ),
            Values.v32.verticalSpace,
            _BeneficiariesList(),
          ],
        ),
      ),
    );
  }

  void _continue(WidgetRef ref, String receipientNumber) {
    if (receipientNumber.isNotEmpty) {
      unawaited(
        ref
            .read(appRouterProvider)
            .push(MakePaymentRoute(recipientNumber: receipientNumber)),
      );
    }
  }
}

class _BeneficiariesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beneficiaryType = ref.watch(beneficiaryTypeControllerProvider);

    final beneficiaries = switch (beneficiaryType) {
      BeneficiaryType.recent => ref.watch(recentBeneficiariesProvider),
      BeneficiaryType.saved => ref.watch(savedBeneficiariesProvider),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Beneficiaries',
          style: context.textTheme.labelMedium?.copyWith(
            letterSpacing: Values.zero,
            fontWeight: FontWeight.w400,
          ),
        ),
        Values.v8.verticalSpace,
        Row(
          children: [
            _BeneficiaryTypeButton(
              beneficiaryType: BeneficiaryType.recent,
              onTap: () => ref
                  .read(beneficiaryTypeControllerProvider.notifier)
                  .switchToRecent(),
            ),
            _BeneficiaryTypeButton(
              beneficiaryType: BeneficiaryType.saved,
              onTap: () => ref
                  .read(beneficiaryTypeControllerProvider.notifier)
                  .switchToSaved(),
            ),
          ],
        ),
        Values.v4.verticalSpace,
        if (beneficiaries.value != null && beneficiaries.value!.isEmpty)
          AppZeroItem(
            topPaddingScaleFactor: .2,
            icon: Icons.group_off_outlined,
            message:
                "No ${beneficiaryType == BeneficiaryType.recent ? 'Recent' : 'Saved'} beneficiary",
          )
        else
          SizedBox(
            height: context.screenHeight * .6,
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: beneficiaries.isLoading
                  ? kMockBeneficiaries.length
                  : beneficiaries.value?.length,
              itemBuilder: (context, index) {
                final data = beneficiaries.isLoading
                    ? kMockBeneficiaries
                    : beneficiaries.value ?? kMockBeneficiaries;

                return _BeneficiaryTile(
                  isLoading: beneficiaries.isLoading,
                  beneficiary: data[index],
                  onTap: () => ref
                      .read(appRouterProvider)
                      .push(
                        MakePaymentRoute(
                          recipientNumber: data[index].accountNumber,
                        ),
                      ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _BeneficiaryTile extends ConsumerWidget {
  const _BeneficiaryTile({
    required this.isLoading,
    required this.beneficiary,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;
  final BeneficiaryModel beneficiary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(appPrimaryColorProvider);

    return Dismissible(
      key: ValueKey<BeneficiaryModel>(beneficiary),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) => deleteBeneficiary(ref),
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: Values.v8),
        color: Colors.redAccent,
        child: Row(
          children: [
            const Icon(
              Icons.delete_outline,
              color: AppColors.white,
            ),
            Text(
              'Delete',
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Values.v10),
          child: Row(
            children: [
              Skeletonizer(
                enabled: isLoading,
                child: Container(
                  width: Values.v48,
                  height: Values.v48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: .22),
                  ),
                  child: isLoading
                      ? null
                      : Text(
                          getInitials(beneficiary.accountName),
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: color,
                          ),
                        ),
                ),
              ),
              Values.v8.horizontalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeletonizer(
                    enabled: isLoading,
                    child: Text(
                      beneficiary.accountName,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Skeletonizer(
                    enabled: isLoading,
                    child: Text(
                      beneficiary.accountNumber,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
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

  Future<void> deleteBeneficiary(WidgetRef ref) async {
    if (beneficiary.id == null) return;

    final beneficiaryType = ref.read(beneficiaryTypeControllerProvider);

    if (beneficiaryType == BeneficiaryType.recent) {
      ref.read(recentBeneficiariesProvider.notifier).removeLocally(beneficiary);
    } else {
      ref.read(savedBeneficiariesProvider.notifier).removeLocally(beneficiary);
    }

    final result = await ref
        .read(transactionRepositoryProvider)
        .deleteBeneficiaryById(beneficiary.id!);

    await result.fold(
      (_) => null,
      (failure) async {
        if (beneficiaryType == BeneficiaryType.recent) {
          await ref.read(recentBeneficiariesProvider.notifier).refresh();
        } else {
          await ref.read(savedBeneficiariesProvider.notifier).refresh();
        }
        ref.showExceptionMessage(failure);
      },
    );
  }
}

class _BeneficiaryTypeButton extends ConsumerWidget {
  const _BeneficiaryTypeButton({
    required this.onTap,
    required this.beneficiaryType,
  });

  final VoidCallback onTap;
  final BeneficiaryType beneficiaryType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(beneficiaryTypeControllerProvider);
    final primaryColor = ref.watch(appPrimaryColorProvider);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Durations.long4,
        padding: const EdgeInsets.all(Values.v10),
        decoration: type != beneficiaryType
            ? null
            : BoxDecoration(
                color: primaryColor.withAlpha(20),
                border: Border.all(color: primaryColor),
                borderRadius: BorderRadius.circular(32),
              ),
        child: Text(
          beneficiaryType.typeName,
          style: context.textTheme.labelMedium?.copyWith(
            color: type != beneficiaryType ? null : primaryColor,
          ),
        ),
      ),
    );
  }
}

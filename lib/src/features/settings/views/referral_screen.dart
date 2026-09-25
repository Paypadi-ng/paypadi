import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:paypadi/config/gen/colors.gen.dart' show AppColors;
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/shared/controllers/user_profile/user_profile_controller.dart';
import 'package:paypadi/src/shared/widgets/app_card.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';

@RoutePage()
class ReferralScreen extends HookConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return AppScaffold(
      title: 'Referrals',
      // topPadding: Values.v24,
      child: AppCard(
        cardColor: AppColors.referralCardColor,
        padding: const EdgeInsets.all(Values.v16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Refer a Friend',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: kZeroLetterSpacing,
              ),
            ),
            Text(
              'Share your referral code with others to get one month of Paypadi free!',
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: kZeroLetterSpacing,
              ),
            ),
            Values.v8.verticalSpace,
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: Values.v8,
                horizontal: Values.v10,
              ),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(Values.v10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    profile.value?.referralCode ?? '',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: AppColors.white,
                      letterSpacing: kZeroLetterSpacing,
                    ),
                  ),

                  GestureDetector(
                    onTap: () => copyCodeToClipBoard(
                      ref,
                      profile.value?.referralCode ?? '',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: Values.v4,
                        horizontal: Values.v8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: .3),
                        borderRadius: BorderRadius.circular(Values.v10),
                      ),
                      child: Text(
                        'Copy',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: AppColors.white,
                          letterSpacing: kZeroLetterSpacing,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Values.v10.verticalSpace,
            Container(
              width: context.screenWidth,
              padding: const EdgeInsets.all(Values.v10),
              decoration: BoxDecoration(
                color: ref.read(appPrimaryColorProvider),
                borderRadius: BorderRadius.circular(Values.v10),
              ),
              child: Column(
                children: [
                  Text(
                    'Signed up',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: kZeroLetterSpacing,
                    ),
                  ),
                  Text(
                    '${profile.value?.totalReferrals ?? 0}',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: kZeroLetterSpacing,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> copyCodeToClipBoard(WidgetRef ref, String code) async {
    final String referCode = 'Use my referral code: $code';
    await Clipboard.setData(ClipboardData(text: referCode)).then(
      (value) => ref.showSuccessToast('Successfully copied information'),
    );
  }
}

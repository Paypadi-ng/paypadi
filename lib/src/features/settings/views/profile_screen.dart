import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/gen/colors.gen.dart';
import 'package:paypadi/core/utils/constants.dart' show kDemoProfilePic, Values;
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/shared/controllers/user_profile/user_profile_controller.dart';
import 'package:paypadi/src/shared/widgets/app_avatar.dart' show AppAvatar;
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';
import 'package:paypadi/src/shared/widgets/app_textformfield.dart'
    show AppTextformfield;

@RoutePage()
class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final firstName = useTextEditingController(text: user.value?.firstName);
    final lastName = useTextEditingController(text: user.value?.lastName);
    final phoneNumber = useTextEditingController(text: user.value?.phoneNumber);

    final style = context.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w400,
    );

    return AppScaffold(
      title: 'Profile',
      makeScrollable: true,
      // bottomPadding: Values.v24,
      child: Column(
        children: [
          Values.v24.verticalSpace,
          const AppAvatar(radius: 80, imageUrl: kDemoProfilePic),
          Values.v8.verticalSpace,
          GestureDetector(
            onTap: () {},
            child: Text(
              'Edit photo',
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Values.v20.verticalSpace,
          AppTextformfield(
            title: 'First Name',
            controller: firstName,
            titleStyle: style,
          ),
          AppTextformfield(
            title: 'Last Name',
            controller: lastName,
            titleStyle: style,
          ),
          AppTextformfield(
            isEnabled: false,
            title: 'Phone Number',
            controller: phoneNumber,
            titleStyle: style,
          ),

          FilledButton(
            onPressed: () {},
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

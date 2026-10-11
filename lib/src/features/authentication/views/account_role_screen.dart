import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/gen/assets.gen.dart';
import 'package:paypadi/gen/colors.gen.dart';
import 'package:paypadi/src/features/authentication/controller/authentication_controller.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';

@RoutePage()
class AccountRoleScreen extends HookConsumerWidget {
  const AccountRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Values.v32.verticalSpace,
          Text(
            'Choose Your Role',
            style: context.textTheme.headlineMedium,
          ),
          Values.v10.verticalSpace,
          Text(
            'Choose your role to get a personalized experience.',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          Values.v32.verticalSpace,
          _RoleWidget(
            role: AccountRole.passenger,
            onWidgetTapped: () {
              ref.read(authenticationPayloadProvider)['role'] = 'rider';
              unawaited(
                ref.read(appRouterProvider).push(const SetupPassengerRoute()),
              );
            },
          ),
          _RoleWidget(
            role: AccountRole.driver,
            onWidgetTapped: () {
              ref.read(authenticationPayloadProvider)['role'] = 'driver';
              unawaited(
                ref.read(appRouterProvider).push(const SetupDriverRoute()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoleWidget extends StatelessWidget {
  const _RoleWidget({required this.role, this.onWidgetTapped});

  final AccountRole role;
  final VoidCallback? onWidgetTapped;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onWidgetTapped,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: Values.v24,
          horizontal: Values.v16,
        ),
        margin: const EdgeInsets.only(bottom: Values.v16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Values.v12.r),
          boxShadow: [
            BoxShadow(
              blurRadius: Values.v4,
              offset: const Offset(Values.zero, Values.v1),
              color: AppColors.black.withValues(alpha: .25),
            ),
          ],
        ),
        child: Row(
          spacing: Values.v16,
          children: [
            switch (role) {
              AccountRole.passenger => AppAssets.illustrations.passenger.svg(),
              AccountRole.driver => AppAssets.illustrations.driver.svg(),
            },
            Expanded(
              child: Column(
                spacing: Values.v6,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.title,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    role.description,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w400,
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
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/wallet/i_wallet_repository.dart';
import 'package:paypadi/data/wallet/models/user_bank_account_model.dart';
import 'package:paypadi/data/wallet/providers.dart';
import 'package:paypadi/features/home/views/deposit_money_screen.dart';

import '../helpers/transfer_fakes.dart';

/// Fails the first deposit-account request, then succeeds.
class _FlakyWalletRepository implements IWalletRepository {
  int calls = 0;

  @override
  FutureApiResultOf<UserBankAccountModel> getDepositAccount() async =>
      calls++ == 0
      ? failure(
          const ServerException.badRequest(
            'Could not generate virtual account. Please use standard deposit.',
          ),
        )
      : success(
          ok(
            const UserBankAccountModel(
              number: '0123456789',
              name: 'Ada Obi',
              bankName: 'Wema Bank',
              bankCode: '035',
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  testWidgets('a failed deposit account shows the reason, not placeholder '
      'details, and can be retried', (tester) async {
    tester.view
      ..physicalSize = appDesignSize * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(_FlakyWalletRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: appDesignSize,
          builder: (_, _) => const MaterialApp(home: DepositMoneyScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not generate virtual account. Please use standard deposit.',
      ),
      findsOneWidget,
    );
    expect(find.text('John Doe'), findsNothing);
    expect(find.text('123456789'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Wema Bank'), findsOneWidget);
    expect(find.text('0123456789'), findsOneWidget);
  });
}

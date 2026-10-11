import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/transaction/models/account_lookup_model.dart';
import 'package:paypadi/data/transaction/models/beneficiary_model.dart';
import 'package:paypadi/data/wallet/i_wallet_repository.dart';
import 'package:paypadi/data/wallet/models/wallet_model.dart';
import 'package:paypadi/data/wallet/providers.dart';
import 'package:paypadi/shared/controllers/app_toast_controller.dart';
import 'package:paypadi/shared/controllers/wallet_controller.dart';

import '../../helpers/transfer_fakes.dart';

final _wallet = WalletModel(
  id: 'w1',
  balance: '5000.00',
  currency: 'NGN',
  reservedBalance: '0.00',
  availableBalance: '5000.00',
  createdAt: DateTime.utc(2026, 10, 1, 9),
  updatedAt: DateTime.utc(2026, 10, 1, 9),
);

class _FakeWalletRepository implements IWalletRepository {
  final List<Map<String, dynamic>> saved = [];

  @override
  FutureApiResultOf<WalletModel> fetchWalletBalance() async =>
      success(ok(_wallet));

  @override
  FutureApiResultOf<BeneficiaryModel> saveBeneficiary(
    Map<String, dynamic> payload,
  ) async {
    saved.add(payload);
    return success(
      ok(
        const BeneficiaryModel(
          type: 'user',
          accountNumber: '0123456789',
          accountName: 'Tunde Bello',
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  test('saving a beneficiary leaves the wallet balance in place', () async {
    final repository = _FakeWalletRepository();
    final container = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(repository),
        appToastControllerProvider.overrideWith(SilentToastController.new),
      ],
    );
    addTearDown(container.dispose);
    container.listen(walletControllerProvider, (_, _) {});
    await container.read(walletControllerProvider.future);

    await container
        .read(walletControllerProvider.notifier)
        .saveBeneficiary(
          const AccountLookupModel(
            role: 'rider',
            firstName: 'Tunde',
            lastName: 'Bello',
            phoneNumber: '08031234567',
            accountNumber: '0123456789',
          ),
        );

    expect(repository.saved.single['account_number'], '0123456789');
    expect(container.read(walletControllerProvider).value, _wallet);
  });
}

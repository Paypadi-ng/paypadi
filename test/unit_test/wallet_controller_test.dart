import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/models/account_lookup_model/account_lookup_model.dart';
import 'package:paypadi/core/models/beneficiary_model/beneficiary_model.dart';
import 'package:paypadi/core/models/wallet_model/wallet_model.dart';
import 'package:paypadi/core/repositories/wallet/i_wallet_repository.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/src/features/home/controller/wallet_controller.dart';
import 'package:paypadi/src/shared/controllers/app_toast/app_toast_controller.dart';

import '../helpers/transfer_fakes.dart';

const _wallet = WalletModel(
  id: 'w1',
  balance: '5000.00',
  currency: 'NGN',
  reservedBalance: '0.00',
  availableBalance: '5000.00',
  createdAt: '2026-10-01T09:00:00Z',
  updatedAt: '2026-10-01T09:00:00Z',
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

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/profile/i_profile_repository.dart';
import 'package:paypadi/data/profile/providers.dart';
import 'package:paypadi/data/transaction/providers.dart';
import 'package:paypadi/features/authentication/controllers/account_security_controller.dart';
import 'package:paypadi/features/transfer/controllers/transaction_controller.dart';
import 'package:paypadi/shared/controllers/app_toast_controller.dart';
import 'package:paypadi/shared/controllers/transfer_draft.dart';

import '../../helpers/transfer_fakes.dart';

class _FakeProfileRepository implements IProfileRepository {
  final List<Map<String, dynamic>> pinChanges = [];
  final List<Map<String, dynamic>> passwordChanges = [];
  Exception? failWith;

  Result<ApiResponse<void>, Exception> _result() =>
      failWith == null ? success(ok<void>(null)) : failure(failWith!);

  @override
  FutureApiResultOf<void> changePin({
    required Map<String, dynamic> payload,
  }) async {
    pinChanges.add(payload);
    return _result();
  }

  @override
  FutureApiResultOf<void> changePassword({
    required Map<String, dynamic> payload,
  }) async {
    passwordChanges.add(payload);
    return _result();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late FakeTransactionRepository transactions;
  late _FakeProfileRepository profile;
  late FakePinVault vault;
  late SilentToastController toasts;
  late ProviderContainer container;

  setUp(() {
    transactions = FakeTransactionRepository();
    profile = _FakeProfileRepository();
    vault = FakePinVault();
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(transactions),
        profileRepositoryProvider.overrideWithValue(profile),
        transactionPinVaultProvider.overrideWithValue(vault),
        appRouterProvider.overrideWith((ref) => RecordingRouter(ref: ref)),
        appToastControllerProvider.overrideWith(SilentToastController.new),
      ],
    );
    addTearDown(container.dispose);
    toasts =
        container.read(appToastControllerProvider.notifier)
            as SilentToastController;
    container.listen(initiatePaymentControllerProvider, (_, _) {});

    container.read(transferDraftControllerProvider.notifier)
      ..start(amount: '1500')
      ..setRecipient(accountNumber: '0123456789', bankCode: '058')
      ..setPin('1234');
  });

  Future<void> initiate({
    bool pinFromVault = false,
    bool rememberPin = false,
    Exception? failWith,
  }) async {
    final call = container
        .read(initiatePaymentControllerProvider.notifier)
        .initiatePayment(pinFromVault: pinFromVault, rememberPin: rememberPin);
    if (failWith == null) {
      transactions.completeInitiate();
    } else {
      transactions.failInitiate(failWith);
    }
    await call;
  }

  group('Biometric PIN after a payment is started', () {
    test('remembers a typed PIN the server accepted', () async {
      await initiate(rememberPin: true);

      expect(vault.saved, ['1234']);
    });

    test('stores nothing when biometric confirmation is off', () async {
      await initiate();

      expect(vault.saved, isEmpty);
    });

    test('never stores a PIN the server refused', () async {
      await initiate(
        rememberPin: true,
        failWith: const ServerException.badRequest('Invalid PIN'),
      );

      expect(vault.saved, isEmpty);
    });

    test('does not re-save a PIN that came from the vault', () async {
      vault.pin = '1234';

      await initiate(pinFromVault: true, rememberPin: true);

      expect(vault.saved, isEmpty);
      expect(vault.clears, 0);
    });

    for (final refusal in const [
      ServerException.badRequest('Invalid PIN'),
      ServerException.forbiddenRequest('Invalid PIN'),
      ServerException.unprocessableEntity('Invalid PIN'),
    ]) {
      test('forgets a vault PIN the server refuses ($refusal)', () async {
        vault.pin = '1234';

        await initiate(pinFromVault: true, failWith: refusal);

        expect(vault.clears, 1);
        expect(vault.pin, isNull);
      });
    }

    for (final unrelated in const [
      ServerException.unauthorizedRequest('Session expired'),
      ServerException.receiveTimeout(),
      ServerException.noInternetConnection(),
      ServerException.internalServerError(),
    ]) {
      test('keeps the vault PIN when the failure says nothing about it '
          '($unrelated)', () async {
        vault.pin = '1234';

        await initiate(pinFromVault: true, failWith: unrelated);

        expect(vault.clears, 0);
        expect(vault.pin, '1234');
      });
    }

    test('never clears the vault for a typed PIN that failed', () async {
      vault.pin = '9999';

      await initiate(failWith: const ServerException.badRequest('Invalid PIN'));

      expect(vault.clears, 0);
    });
  });

  group('AccountSecurity.changePin', () {
    Future<void> changePin() => container
        .read(accountSecurityProvider.notifier)
        .changePin(currentPin: '1111', newPin: '2222', confirmedPin: '2222');

    setUp(() => container.listen(accountSecurityProvider, (_, _) {}));

    test('sends the PIN the user typed as the current PIN', () async {
      await changePin();

      expect(profile.pinChanges.single, {
        'current_pin': '1111',
        'new_pin': '2222',
        'confirm_pin': '2222',
      });
    });

    test('forgets the biometric copy of the old PIN once changed', () async {
      vault.pin = '1111';

      await changePin();

      expect(vault.clears, 1);
      expect(vault.saved, isEmpty, reason: 'the new PIN is never stored here');
    });

    test('keeps the biometric copy when the change is refused', () async {
      vault.pin = '1111';
      profile.failWith = const ServerException.badRequest('Wrong PIN');

      await changePin();

      expect(vault.clears, 0);
      expect(toasts.errors, hasLength(1));
    });
  });

  group('AccountSecurity.changePassword', () {
    setUp(() => container.listen(accountSecurityProvider, (_, _) {}));

    test('sends the password the user typed as the current one', () async {
      await container
          .read(accountSecurityProvider.notifier)
          .changePassword(currentPassword: '135790', newPassword: '246801');

      expect(profile.passwordChanges.single, {
        'old_password': '135790',
        'new_password': '246801',
      });
    });
  });
}

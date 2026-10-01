import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:paypadi/config/router/router.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/models/account_lookup_model/account_lookup_model.dart';
import 'package:paypadi/core/models/payment_model/payment_model.dart';
import 'package:paypadi/core/models/transaction_model/transaction_model.dart';
import 'package:paypadi/core/repositories/transaction/i_transaction_repository.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/src/shared/controllers/app_toast/app_toast_controller.dart';

const kTransaction = TransactionModel(
  amount: 1500,
  reference: 'PPD-123',
  recipient: '0123456789',
  recipientAccount: 'Tunde Bello',
  createdAt: '2026-10-01T09:00:00Z',
  paymentType: 'wallet',
  type: TransactionType.transfer,
);

const kPayment = PaymentModel(
  amount: '1500',
  reference: 'PPD-123',
  authorizationUrl: 'https://checkout.test/abc',
  transactionId: 'txn_1',
  createdAt: '2026-10-01T09:00:00Z',
  paymentType: TransactionType.transfer,
);

ApiResponse<T> ok<T>(T data) =>
    ApiResponse(status: true, message: 'OK', data: data);

/// A transaction repository whose transfer and initiate calls stay pending
/// until the test completes them, and which records every payload sent.
class FakeTransactionRepository implements ITransactionRepository {
  final List<Map<String, dynamic>> transfers = [];
  final List<Map<String, dynamic>> initiations = [];
  final List<Map<String, dynamic>> lookups = [];

  final _transfer =
      Completer<Result<ApiResponse<TransactionModel>, Exception>>();
  final _initiate = Completer<Result<ApiResponse<PaymentModel>, Exception>>();

  void completeTransfer() => _transfer.complete(success(ok(kTransaction)));

  void failTransfer() => _transfer.complete(
    failure(const ServerException.badRequest('Insufficient funds')),
  );

  void completeInitiate() => _initiate.complete(success(ok(kPayment)));

  @override
  FutureResultOf<ApiResponse<TransactionModel>> transfer(
    Map<String, dynamic> payload,
  ) {
    transfers.add(payload);
    return _transfer.future;
  }

  @override
  FutureResultOf<ApiResponse<PaymentModel>> initiatePayment(
    Map<String, dynamic> payload,
  ) {
    initiations.add(payload);
    return _initiate.future;
  }

  @override
  FutureApiResultOf<AccountLookupModel> getAccountDetails(
    Map<String, dynamic> payload,
  ) async {
    lookups.add(payload);
    return success(
      ok(
        const AccountLookupModel(
          role: 'rider',
          firstName: 'Tunde',
          lastName: 'Bello',
          phoneNumber: '08031234567',
          accountNumber: '0123456789',
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Records pushes instead of navigating.
class RecordingRouter extends AppRouter {
  RecordingRouter({required super.ref});
  final List<PageRouteInfo> pushed = [];

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushed.add(route);
    return null;
  }
}

/// Swallows toasts, which need an overlay the tests don't build.
class SilentToastController extends AppToastController {
  final List<Object?> errors = [];

  @override
  void showExceptionMessage(Object? error, [StackTrace? stackTrace]) =>
      errors.add(error);

  @override
  void showError(String message) => errors.add(message);
}

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/clients/payout_account/payout_account_client.dart';
import 'package:paypadi/core/models/user_bank_account_model/user_bank_account_model.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/src/features/home/views/deposit_money_screen.dart';

/// Records each request path instead of sending it.
class _CapturingAdapter implements HttpClientAdapter {
  final List<String> paths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('TransactionStatus.fromApi', () {
    test('maps the common spellings', () {
      const cases = {
        'success': TransactionStatus.success,
        'Successful': TransactionStatus.success,
        'completed': TransactionStatus.completed,
        'pending': TransactionStatus.pending,
        'processing': TransactionStatus.pending,
        'failed': TransactionStatus.failure,
        'declined': TransactionStatus.failure,
      };
      for (final MapEntry(key: value, value: expected) in cases.entries) {
        expect(TransactionStatus.fromApi(value), expected, reason: value);
      }
    });

    test('shows anything else as unknown rather than failed', () {
      expect(TransactionStatus.fromApi('reversed'), TransactionStatus.unknown);
      expect(TransactionStatus.fromApi(null), TransactionStatus.unknown);
    });
  });

  group('PayoutAccountClient', () {
    late _CapturingAdapter adapter;
    late PayoutAccountClient client;

    setUp(() {
      adapter = _CapturingAdapter();
      client = PayoutAccountClient(
        Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
      );
    });

    // The canned body doesn't parse; only the request path matters here.
    Future<void> send(Future<Object?> Function() call) async {
      try {
        await call();
      } on Object catch (_) {}
    }

    test('builds account paths without a double slash', () async {
      await send(() => client.getAccountById(id: '4'));
      await send(() => client.createPayoutAccount(payload: {}));

      expect(adapter.paths, [
        '/auth/driver/payout-accounts/4/',
        '/auth/driver/payout-accounts/',
      ]);
    });
  });

  test('deposit details label the bank as the bank', () {
    const account = UserBankAccountModel(
      number: '0123456789',
      name: 'Ada Obi',
      bankName: 'Wema Bank',
      bankCode: '035',
    );

    expect(
      depositAccountDetails(account),
      'Bank: Wema Bank\nAccount Name: Ada Obi\nAccount Number: 0123456789',
    );
  });
}

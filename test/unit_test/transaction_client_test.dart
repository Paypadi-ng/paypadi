import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/clients/transaction/transaction_client.dart';

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
  late _CapturingAdapter adapter;
  late TransactionClient client;

  setUp(() {
    adapter = _CapturingAdapter();
    client = TransactionClient(
      Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );
  });

  // The canned `{}` body doesn't parse; only the request path matters here.
  Future<void> send(Future<Object?> Function() call) async {
    try {
      await call();
    } on Object catch (_) {}
  }

  test('withdrawals go to the withdraw endpoint', () async {
    await send(() => client.withdraw(payload: {'amount': '1500'}));
    expect(adapter.paths.single, '/wallets/withdraw/');
  });

  test('deposits go to the deposit endpoint', () async {
    await send(() => client.deposit(payload: {'amount': 1500}));
    expect(adapter.paths.single, '/wallets/deposit/');
  });

  test('transfers still go to the transfer endpoint', () async {
    await send(() => client.transfer(payload: {'amount': '1500'}));
    expect(adapter.paths.single, '/wallets/transfer/');
  });
}

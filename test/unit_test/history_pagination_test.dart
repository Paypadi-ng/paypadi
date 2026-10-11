import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/transaction/models/transaction_model.dart';
import 'package:paypadi/data/wallet/i_wallet_repository.dart';
import 'package:paypadi/data/wallet/providers.dart';
import 'package:paypadi/features/home/controllers/wallet_controller.dart';
import 'package:paypadi/shared/controllers/app_toast_controller.dart';

import '../helpers/transfer_fakes.dart';

TransactionHistoryModel _transaction(String id) => TransactionHistoryModel(
  id: id,
  amount: '100.00',
  reference: 'REF-$id',
  status: TransactionStatus.success,
  type: TransactionType.transfer,
  createdAt: DateTime.utc(2026, 10, 1, 9),
  senderName: 'Ada Obi',
  recipientName: 'Tunde Bello',
  transactionFee: '0.00',
);

/// Serves [pages] of history; a page listed in [failing] fails once.
class _PagedWalletRepository implements IWalletRepository {
  _PagedWalletRepository(this.pages);
  final List<List<String>> pages;
  final Set<int> failing = {};
  final List<int> requested = [];
  Completer<void>? gate;

  @override
  FuturePaginatedApiOf<TransactionHistoryModel> getTransactionHistory({
    int page = 1,
    int pageSize = 10,
  }) async {
    requested.add(page);
    await gate?.future;
    if (failing.remove(page)) {
      return failure(const ServerException.noInternetConnection());
    }
    return success(
      ok(
        PaginatedListResponse(
          count: pages.expand((page) => page).length,
          results: [for (final id in pages[page - 1]) _transaction(id)],
          next: page < pages.length
              ? 'https://api.test/?page=${page + 1}'
              : null,
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _PagedWalletRepository repository;
  late ProviderContainer container;

  Future<TransactionHistory> start(List<List<String>> pages) async {
    repository = _PagedWalletRepository(pages);
    container = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(repository),
        appToastControllerProvider.overrideWith(SilentToastController.new),
      ],
    );
    addTearDown(container.dispose);
    container.listen(historyControllerProvider, (_, _) {});
    return container.read(historyControllerProvider.future);
  }

  HistoryController history() =>
      container.read(historyControllerProvider.notifier);
  TransactionHistory? state() =>
      container.read(historyControllerProvider).value;
  List<String> ids() => [for (final item in state()!.items) item.id];

  test('loads the first page and knows there is more', () async {
    final first = await start([
      ['a', 'b'],
      ['c'],
    ]);

    expect([for (final item in first.items) item.id], ['a', 'b']);
    expect(first.hasMore, isTrue);
  });

  test('appends each next page until the last', () async {
    await start([
      ['a', 'b'],
      ['c', 'd'],
      ['e'],
    ]);

    await history().loadMore();
    await history().loadMore();

    expect(ids(), ['a', 'b', 'c', 'd', 'e']);
    expect(state()!.hasMore, isFalse);
    expect(repository.requested, [1, 2, 3]);

    await history().loadMore();
    expect(repository.requested, [1, 2, 3]);
  });

  test('keeps what is loaded when the next page fails', () async {
    await start([
      ['a', 'b'],
      ['c'],
    ]);
    repository.failing.add(2);

    await history().loadMore();

    expect(ids(), ['a', 'b']);
    expect(state()!.hasMore, isTrue);
    expect(state()!.isLoadingMore, isFalse);
  });

  test('ignores a second request while a page is loading', () async {
    await start([
      ['a'],
      ['b'],
    ]);
    repository.gate = Completer<void>();

    final first = history().loadMore();
    final second = history().loadMore();
    repository.gate!.complete();
    await Future.wait([first, second]);

    expect(repository.requested, [1, 2]);
    expect(ids(), ['a', 'b']);
  });
}

import 'package:paypadi/core/providers.dart';
import 'package:paypadi/data/transaction/i_transaction_client.dart';
import 'package:paypadi/data/transaction/i_transaction_repository.dart';
import 'package:paypadi/data/transaction/transaction_client.dart';
import 'package:paypadi/data/transaction/transaction_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
ITransactionClient transactionClient(Ref ref) {
  return TransactionClient(ref.watch(dioProvider));
}

@riverpod
ITransactionRepository transactionRepository(Ref ref) {
  return TransactionRepository(client: ref.watch(transactionClientProvider));
}

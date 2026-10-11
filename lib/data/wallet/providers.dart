import 'package:paypadi/core/providers.dart';
import 'package:paypadi/data/wallet/i_wallet_client.dart';
import 'package:paypadi/data/wallet/i_wallet_repository.dart';
import 'package:paypadi/data/wallet/wallet_client.dart';
import 'package:paypadi/data/wallet/wallet_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
IWalletClient walletClient(Ref ref) {
  return WalletClient(ref.watch(dioProvider));
}

@riverpod
IWalletRepository walletRepository(Ref ref) {
  return WalletRepository(client: ref.watch(walletClientProvider));
}

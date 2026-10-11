import 'package:paypadi/core/providers.dart';
import 'package:paypadi/data/payout_account/i_payout_account_client.dart';
import 'package:paypadi/data/payout_account/i_payout_account_repository.dart';
import 'package:paypadi/data/payout_account/payout_account_client.dart';
import 'package:paypadi/data/payout_account/payout_account_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
IPayoutAccountClient payoutAccountClient(Ref ref) {
  return PayoutAccountClient(ref.watch(dioProvider));
}

@riverpod
IPayoutAccountRepository payoutAccountRepository(Ref ref) {
  return PayoutAccountRepository(
    client: ref.watch(payoutAccountClientProvider),
  );
}

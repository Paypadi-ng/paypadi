import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/payout_account/models/account_payout_model.dart';
import 'package:paypadi/data/payout_account/models/bank_model.dart';

abstract interface class IPayoutAccountRepository {
  FutureResultListOf<BankModel> getListOfBanks();

  FutureApiResultOf<AccountPayoutModel> createAccount(
    Map<String, dynamic> payload,
  );
}

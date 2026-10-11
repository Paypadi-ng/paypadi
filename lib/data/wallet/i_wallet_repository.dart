import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/payout_account/models/bank_model.dart';
import 'package:paypadi/data/transaction/models/beneficiary_model.dart';
import 'package:paypadi/data/transaction/models/transaction_model.dart';
import 'package:paypadi/data/wallet/models/user_bank_account_model.dart';
import 'package:paypadi/data/wallet/models/wallet_model.dart';

abstract interface class IWalletRepository {
  FutureApiResultOf<WalletModel> fetchWalletBalance();

  FutureApiResultOf<UserBankAccountModel> getDepositAccount();

  FuturePaginatedApiOf<TransactionHistoryModel> getTransactionHistory({
    int page = 1,
    int pageSize = 10,
  });

  FutureResultOf<VerifiedBankAccountModel> verifyBankInformation(
    Map<String, dynamic> payload,
  );

  FutureApiResultOf<BeneficiaryModel> saveBeneficiary(
    Map<String, dynamic> payload,
  );
}

import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/data/payout_account/models/bank_model.dart';
import 'package:paypadi/data/transaction/models/beneficiary_model.dart';
import 'package:paypadi/data/transaction/models/transaction_model.dart';
import 'package:paypadi/data/wallet/models/user_bank_account_model.dart';
import 'package:paypadi/data/wallet/models/wallet_model.dart';

abstract interface class IWalletClient {
  Future<ApiResponse<WalletModel>> getBalance();

  Future<ApiResponse<PaginatedListResponse<TransactionHistoryModel>>>
  getTransactionHistory({
    required int page,
    required int pageSize,
  });

  Future<ApiResponse<UserBankAccountModel>> getDepositAccount();

  Future<ApiResponse<BeneficiaryModel>> saveBeneficiary({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<VerifiedBankAccountModel>> verifyBankInformation({
    required Map<String, dynamic> payload,
  });
}

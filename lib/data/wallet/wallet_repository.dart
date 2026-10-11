import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/payout_account/models/bank_model.dart';
import 'package:paypadi/data/transaction/models/beneficiary_model.dart';
import 'package:paypadi/data/transaction/models/transaction_model.dart';
import 'package:paypadi/data/wallet/i_wallet_client.dart';
import 'package:paypadi/data/wallet/i_wallet_repository.dart';
import 'package:paypadi/data/wallet/models/user_bank_account_model.dart';
import 'package:paypadi/data/wallet/models/wallet_model.dart';

class WalletRepository implements IWalletRepository {
  const WalletRepository({required IWalletClient client}) : _client = client;
  final IWalletClient _client;

  @override
  FutureApiResultOf<WalletModel> fetchWalletBalance() async {
    final response = await Result.fromAsync<ApiResponse<WalletModel>>(
      _client.getBalance,
    );
    return response;
  }

  @override
  FutureApiResultOf<UserBankAccountModel> getDepositAccount() async {
    final response = await Result.fromAsync<ApiResponse<UserBankAccountModel>>(
      _client.getDepositAccount,
    );
    return response;
  }

  @override
  FuturePaginatedApiOf<TransactionHistoryModel> getTransactionHistory({
    int page = 1,
    int pageSize = 10,
  }) async {
    final response =
        await Result.fromAsync<
          ApiResponse<PaginatedListResponse<TransactionHistoryModel>>
        >(() => _client.getTransactionHistory(page: page, pageSize: pageSize));
    return response;
  }

  @override
  FutureResultOf<VerifiedBankAccountModel> verifyBankInformation(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<VerifiedBankAccountModel>(
      () async {
        final result = await _client.verifyBankInformation(payload: payload);
        return result.data;
      },
    );
    return response;
  }

  @override
  FutureApiResultOf<BeneficiaryModel> saveBeneficiary(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<ApiResponse<BeneficiaryModel>>(
      () => _client.saveBeneficiary(payload: payload),
    );
    return response;
  }
}

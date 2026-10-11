import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/data/payout_account/models/account_payout_model.dart';
import 'package:paypadi/data/payout_account/models/bank_model.dart';

abstract interface class IPayoutAccountClient {
  Future<ApiResponse<AccountPayoutModel>> createPayoutAccount({
    required Map<String, dynamic> payload,
  });

  Future<ApiListResponse<BankModel>> getListOfAllBanks();

  Future<ApiResponse<AccountPayoutModel>> getAccountById({
    required String id,
  });

  Future<ApiResponse<AccountPayoutModel>> makeAccountWithIdPrimary({
    required String id,
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<AccountPayoutModel>> verfiyAccountWithId({
    required String id,
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<AccountPayoutModel>> updateAccount({
    required String id,
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<AccountPayoutModel>> partiallyUpdateAccount({
    required String id,
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<void>> deleteAccount({
    required String id,
  });
}

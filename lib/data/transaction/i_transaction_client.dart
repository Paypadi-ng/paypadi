import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/data/transaction/models/account_lookup_model.dart';
import 'package:paypadi/data/transaction/models/beneficiary_model.dart';
import 'package:paypadi/data/transaction/models/payment_model.dart';
import 'package:paypadi/data/transaction/models/transaction_model.dart';

abstract interface class ITransactionClient {
  Future<ApiResponse<PaymentModel>> initiatePayment({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<TransactionModel>> transfer({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<TransactionModel>> withdraw({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<TransactionModel>> deposit({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<AccountLookupModel>> getAccountDetails({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<PaginatedListResponse<BeneficiaryModel>>>
  getSavedBeneficiaries();

  Future<ApiListResponse<BeneficiaryModel>> getRecentBeneficiaries();

  Future<ApiResponse<TransactionHistoryModel>> getTransactionByRefNo({
    required String reference,
  });

  Future<void> deleteBeneficiary({
    required String beneficiaryId,
  });
}

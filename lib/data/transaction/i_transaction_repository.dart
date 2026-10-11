import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/transaction/models/account_lookup_model.dart';
import 'package:paypadi/data/transaction/models/beneficiary_model.dart';
import 'package:paypadi/data/transaction/models/payment_model.dart';
import 'package:paypadi/data/transaction/models/transaction_model.dart';

abstract interface class ITransactionRepository {
  FutureResultOf<ApiResponse<PaymentModel>> initiatePayment(
    Map<String, dynamic> payload,
  );

  FutureResultOf<ApiResponse<TransactionModel>> transfer(
    Map<String, dynamic> payload,
  );

  FutureResultOf<ApiListResponse<BeneficiaryModel>> getRecentBeneficiaries();

  FuturePaginatedApiOf<BeneficiaryModel> getSavedBeneficiaries();

  FutureApiResultOf<AccountLookupModel> getAccountDetails(
    Map<String, dynamic> payload,
  );

  FutureApiResultOf<TransactionHistoryModel> getTransactionDetailsById(
    String reference,
  );

  FutureResultOf<void> deleteBeneficiaryById(
    String beneficiaryId,
  );
}

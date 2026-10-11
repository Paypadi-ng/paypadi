import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/transaction/i_transaction_client.dart';
import 'package:paypadi/data/transaction/i_transaction_repository.dart';
import 'package:paypadi/data/transaction/models/account_lookup_model.dart';
import 'package:paypadi/data/transaction/models/beneficiary_model.dart';
import 'package:paypadi/data/transaction/models/payment_model.dart';
import 'package:paypadi/data/transaction/models/transaction_model.dart';

class TransactionRepository implements ITransactionRepository {
  const TransactionRepository({required ITransactionClient client})
    : _client = client;
  final ITransactionClient _client;

  @override
  FutureResultOf<ApiResponse<PaymentModel>> initiatePayment(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<ApiResponse<PaymentModel>>(
      () => _client.initiatePayment(payload: payload),
    );
    return response;
  }

  @override
  FutureResultOf<ApiResponse<TransactionModel>> transfer(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<ApiResponse<TransactionModel>>(
      () => _client.transfer(payload: payload),
    );
    return response;
  }

  @override
  FutureResultOf<ApiListResponse<BeneficiaryModel>>
  getRecentBeneficiaries() async {
    final response = await Result.fromAsync<ApiListResponse<BeneficiaryModel>>(
      _client.getRecentBeneficiaries,
    );
    return response;
  }

  @override
  FuturePaginatedApiOf<BeneficiaryModel> getSavedBeneficiaries() async {
    final response =
        await Result.fromAsync<
          ApiResponse<PaginatedListResponse<BeneficiaryModel>>
        >(_client.getSavedBeneficiaries);
    return response;
  }

  @override
  FutureApiResultOf<AccountLookupModel> getAccountDetails(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<ApiResponse<AccountLookupModel>>(
      () => _client.getAccountDetails(payload: payload),
    );
    return response;
  }

  @override
  FutureApiResultOf<TransactionHistoryModel> getTransactionDetailsById(
    String reference,
  ) async {
    final response =
        await Result.fromAsync<ApiResponse<TransactionHistoryModel>>(
          () => _client.getTransactionByRefNo(reference: reference),
        );
    return response;
  }

  @override
  FutureResultOf<void> deleteBeneficiaryById(String beneficiaryId) async {
    final response = await Result.fromAsync<void>(
      () => _client.deleteBeneficiary(beneficiaryId: beneficiaryId),
    );
    return response;
  }
}

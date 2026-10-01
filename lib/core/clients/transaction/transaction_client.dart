import 'package:dio/dio.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/clients/transaction/i_transaction_client.dart';
import 'package:paypadi/core/models/account_lookup_model/account_lookup_model.dart';
import 'package:paypadi/core/models/beneficiary_model/beneficiary_model.dart';
import 'package:paypadi/core/models/payment_model/payment_model.dart';
import 'package:paypadi/core/models/transaction_model/transaction_model.dart';
import 'package:retrofit/retrofit.dart';

part 'transaction_client.g.dart';

const String _basePath = '/wallets';

@RestApi()
abstract class TransactionClient implements ITransactionClient {
  factory TransactionClient(Dio dio, {String baseUrl}) = _TransactionClient;

  @override
  @POST('$_basePath/payments/initiate/')
  Future<ApiResponse<PaymentModel>> initiatePayment({
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @POST('$_basePath/transfer/')
  Future<ApiResponse<TransactionModel>> transfer({
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @POST('$_basePath/withdraw/')
  Future<ApiResponse<TransactionModel>> withdraw({
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @POST('$_basePath/deposit/')
  Future<ApiResponse<TransactionModel>> deposit({
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @POST('$_basePath/payments/lookup/')
  Future<ApiResponse<AccountLookupModel>> getAccountDetails({
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @GET('$_basePath/beneficiaries/')
  Future<ApiResponse<PaginatedListResponse<BeneficiaryModel>>>
  getSavedBeneficiaries();

  @override
  @GET('$_basePath/beneficiaries/recent/')
  Future<ApiListResponse<BeneficiaryModel>> getRecentBeneficiaries();

  @override
  @GET('$_basePath/transactions/{reference}/')
  Future<ApiResponse<TransactionHistoryModel>> getTransactionByRefNo({
    @Path('reference') required String reference,
  });

  @override
  @DELETE('$_basePath/beneficiaries/{id}/')
  Future<void> deleteBeneficiary({
    @Path('id') required String beneficiaryId,
  });
}

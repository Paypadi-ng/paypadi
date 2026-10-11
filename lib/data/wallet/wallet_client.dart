import 'package:dio/dio.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/data/payout_account/models/bank_model.dart';
import 'package:paypadi/data/transaction/models/beneficiary_model.dart';
import 'package:paypadi/data/transaction/models/transaction_model.dart';
import 'package:paypadi/data/wallet/i_wallet_client.dart';
import 'package:paypadi/data/wallet/models/user_bank_account_model.dart';
import 'package:paypadi/data/wallet/models/wallet_model.dart';
import 'package:retrofit/retrofit.dart';

part 'wallet_client.g.dart';

const String _basePath = '/wallets';

@RestApi()
abstract class WalletClient implements IWalletClient {
  factory WalletClient(Dio dio, {String baseUrl}) = _WalletClient;

  @override
  @GET('$_basePath/wallet/')
  Future<ApiResponse<WalletModel>> getBalance();

  @override
  @GET('$_basePath/transactions/')
  Future<ApiResponse<PaginatedListResponse<TransactionHistoryModel>>>
  getTransactionHistory({
    @Query('page') required int page,
    @Query('page_size') required int pageSize,
  });

  @override
  @GET('$_basePath/deposit/account/')
  Future<ApiResponse<UserBankAccountModel>> getDepositAccount();

  @override
  @POST('$_basePath/beneficiaries/')
  Future<ApiResponse<BeneficiaryModel>> saveBeneficiary({
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @POST('$_basePath/bank/verify/')
  Future<ApiResponse<VerifiedBankAccountModel>> verifyBankInformation({
    @Body() required Map<String, dynamic> payload,
  });
}

import 'package:dio/dio.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/clients/payout_account/i_payout_account_client.dart';
import 'package:paypadi/core/models/account_payout_model/account_payout_model.dart';
import 'package:paypadi/core/models/bank_model/bank_model.dart';
import 'package:retrofit/retrofit.dart';

part 'payout_account_client.g.dart';

const String _basePath = '/auth/driver/payout-accounts';

@RestApi()
abstract class PayoutAccountClient implements IPayoutAccountClient {
  factory PayoutAccountClient(Dio dio, {String baseUrl}) = _PayoutAccountClient;

  // @GET(_basePath)
  // Future<ApiResponse<AccountPayoutModel>> getListOfAllAccounts({
  //   @Query("page") required int page,
  // });

  @override
  @POST('$_basePath/')
  Future<ApiResponse<AccountPayoutModel>> createPayoutAccount({
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @GET('/auth/banks/')
  Future<ApiListResponse<BankModel>> getListOfAllBanks();

  @override
  @GET('$_basePath/{id}/')
  Future<ApiResponse<AccountPayoutModel>> getAccountById({
    @Path('id') required String id,
  });

  @override
  @POST('$_basePath/{id}/set_primary/')
  Future<ApiResponse<AccountPayoutModel>> makeAccountWithIdPrimary({
    @Path('id') required String id,
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @POST('$_basePath/{id}/verify/')
  Future<ApiResponse<AccountPayoutModel>> verfiyAccountWithId({
    @Path('id') required String id,
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @PUT('$_basePath/{id}/')
  Future<ApiResponse<AccountPayoutModel>> updateAccount({
    @Path('id') required String id,
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @PATCH('$_basePath/{id}/')
  Future<ApiResponse<AccountPayoutModel>> partiallyUpdateAccount({
    @Path('id') required String id,
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @DELETE('$_basePath/{id}/')
  Future<ApiResponse<void>> deleteAccount({
    @Path('id') required String id,
  });
}

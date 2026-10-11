import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/payout_account/i_payout_account_client.dart';
import 'package:paypadi/data/payout_account/i_payout_account_repository.dart';
import 'package:paypadi/data/payout_account/models/account_payout_model.dart';
import 'package:paypadi/data/payout_account/models/bank_model.dart';

class PayoutAccountRepository implements IPayoutAccountRepository {
  const PayoutAccountRepository({required IPayoutAccountClient client})
    : _client = client;
  final IPayoutAccountClient _client;

  @override
  FutureResultListOf<BankModel> getListOfBanks() async {
    final response = await Result.fromAsync<List<BankModel>>(
      () async {
        final banks = await _client.getListOfAllBanks();
        return banks.data;
      },
    );
    return response;
  }

  @override
  FutureApiResultOf<AccountPayoutModel> createAccount(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<ApiResponse<AccountPayoutModel>>(
      () async => _client.createPayoutAccount(payload: payload),
    );
    return response;
  }
}

import 'package:paypadi/data/payout_account/models/bank_model.dart';
import 'package:paypadi/data/payout_account/providers.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bank_list_controller.g.dart';

@riverpod
class BankListController extends _$BankListController {
  @override
  FutureOr<List<BankModel>> build() async {
    final repository = ref.watch(payoutAccountRepositoryProvider);
    final result = await repository.getListOfBanks();

    return result.fold(
      (success) => success,
      (failure) {
        ref.showExceptionMessage(failure);
        return <BankModel>[];
      },
    );
  }

  Future<void> refresh() {
    ref.invalidateSelf();
    return future;
  }
}

import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/data/transaction/models/beneficiary_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'beneficiaries_controller.g.dart';

@riverpod
class RecentBeneficiaries extends _$RecentBeneficiaries {
  @override
  FutureOr<List<BeneficiaryModel>> build() async {
    final repository = ref.watch(transactionRepositoryProvider);
    final result = await repository.getRecentBeneficiaries();

    return result.fold(
      (success) => success.data,
      (failure) => throw failure,
    );
  }

  void removeLocally(BeneficiaryModel beneficiary) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.where((b) => b.id != beneficiary.id).toList(),
    );
  }

  Future<void> refresh() {
    ref.invalidateSelf();
    return future;
  }
}

@riverpod
class SavedBeneficiaries extends _$SavedBeneficiaries {
  @override
  FutureOr<List<BeneficiaryModel>> build() async {
    final repository = ref.watch(transactionRepositoryProvider);
    final result = await repository.getSavedBeneficiaries();

    return result.fold(
      (success) => success.data.results,
      (failure) => throw failure,
    );
  }

  void removeLocally(BeneficiaryModel beneficiary) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.where((b) => b.id != beneficiary.id).toList(),
    );
  }

  Future<void> refresh() {
    ref.invalidateSelf();
    return future;
  }
}

@riverpod
class BeneficiaryTypeController extends _$BeneficiaryTypeController {
  @override
  BeneficiaryType build() => BeneficiaryType.recent;

  void switchToSaved() => state = BeneficiaryType.saved;
  void switchToRecent() => state = BeneficiaryType.recent;
}

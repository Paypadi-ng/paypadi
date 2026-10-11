import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_color_controller.g.dart';

@Riverpod(keepAlive: true)
class ColorIndexNotifier extends _$ColorIndexNotifier {
  @override
  Future<int> build() async {
    // 1. Await the cache service asynchronously
    final cache = await ref.watch(localCacheProvider.future);

    // 2. Fetch the color index from the cache
    final int? index = await cache.get<int>(CacheKeys.inAppColor);

    // 3. Validate and return the index
    final isValid =
        index != null && index >= 0 && index < availableColors.length;
    return isValid ? index : 0;
  }

  Future<void> setColorIndex(int index) async {
    if (index < 0 || index >= availableColors.length) {
      return;
    }

    // Update the local state immediately so the UI responds instantly
    state = AsyncData(index);

    // Persist the change to the cache
    final cache = await ref.read(localCacheProvider.future);
    await cache.save(key: CacheKeys.inAppColor, value: index);
  }
}

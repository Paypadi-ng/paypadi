import 'dart:async';

import 'package:paypadi/core/utils/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  Timer? _timer;
  static const _interval = Duration(seconds: 3);

  static final _keys = onboardingStoryAndAsset.keys.toList();
  static final _values = onboardingStoryAndAsset.values.toList();

  static int get pageCount => onboardingStoryAndAsset.length;
  static List<String> get keys => _keys;
  static List<String> get values => _values;

  @override
  int build() {
    _timer ??= Timer.periodic(_interval, (_) => _advance());

    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    return 0;
  }

  void _advance() {
    state = (state + 1) % pageCount;
  }

  void onPageChanged(int index) => state = index;
}

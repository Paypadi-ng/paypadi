import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_loading_controller.g.dart';

@riverpod
class AppLoadingController extends _$AppLoadingController {
  @override
  bool build() => false;

  void show() => state = true;

  void dismiss() => state = false;
}

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/shared/controllers/app_loading_controller.dart';
import 'package:paypadi/shared/controllers/app_toast_controller.dart';

extension RefExt on Ref {
  void showExceptionMessage(Object? error, [StackTrace? stackTrace]) => read(
    appToastControllerProvider.notifier,
  ).showExceptionMessage(error, stackTrace);
}

extension WidgetRefExt on WidgetRef {
  void showSuccessToast(String message) => _toast.showSuccess(message);

  void showErrorToast(String message) => _toast.showError(message);

  void showExceptionMessage(Object? error, [StackTrace? stackTrace]) =>
      _toast.showExceptionMessage(error, stackTrace);

  AppToastController get _toast => read(appToastControllerProvider.notifier);

  void showLoading() => read(appLoadingControllerProvider.notifier).show();

  void dismissLoading() =>
      read(appLoadingControllerProvider.notifier).dismiss();

  void closeKeyboard() => FocusManager.instance.primaryFocus?.unfocus();
}

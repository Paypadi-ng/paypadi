import 'package:flutter/material.dart';
import 'package:paypadi/core/api/exceptions/app_exception.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/toasts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:toastification/toastification.dart';

part 'app_toast_controller.g.dart';

@riverpod
class AppToastController extends _$AppToastController {
  @override
  void build() {}

  void showInfo(String message) => _show(InfoToast(message));

  void showSuccess(String message) => _show(SuccessToast(message));

  void showError(String message) => _show(ErrorToast(message));

  void showExceptionMessage(Object? error, [StackTrace? stackTrace]) {
    final exception = error is AppException
        ? error
        : AppException.handleException(error);
    showError(AppException.getExceptionMessage(exception));
  }

  void _show(ToastMessage toast) {
    final trimmed = toast.text.trim();
    if (trimmed.isEmpty) return;

    // Dismiss any in-flight toast so rapid-fire calls
    // don't stack visually (e.g. multiple failed network requests).
    toastification.dismissAll(delayForAnimation: false);

    toastification.show(
      title: Text(toast.title),
      description: Text(trimmed),
      type: toast.type,
      icon: toast.icon,
      style: ToastificationStyle.flat,
      alignment: Alignment.topCenter,
      applyBlurEffect: true,
      borderRadius: BorderRadius.circular(Values.v120),
      autoCloseDuration: const Duration(seconds: 4),
      animationBuilder: (context, animation, alignment, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}

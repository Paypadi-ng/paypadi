import 'package:flutter/material.dart';
import 'package:paypadi/core/utils/constants.dart' show debugLogger;

extension BuildContextExt on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  double get screenHeight => MediaQuery.sizeOf(this).height;

  TextTheme get textTheme => Theme.of(this).textTheme;

  FilledButtonThemeData get filledButtonTheme =>
      Theme.of(this).filledButtonTheme;

  double get devicePixelRatio => MediaQuery.devicePixelRatioOf(this);
}

extension NullObjectExt on Object? {
  void printLog([Object? exception, StackTrace? stackTrace]) =>
      debugLogger.debug(this, exception, stackTrace);
}

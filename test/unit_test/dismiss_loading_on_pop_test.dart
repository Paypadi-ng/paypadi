import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/src/shared/widgets/loading_indicator.dart';

void main() {
  testWidgets('dismisses the loading overlay when the user goes back', (
    tester,
  ) async {
    var dismissals = 0;

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [DismissLoadingOnPop(() => dismissals++)],
        home: const Text('Home'),
      ),
    );
    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(
            MaterialPageRoute<void>(builder: (_) => const Text('Payment')),
          ),
    );
    await tester.pumpAndSettle();
    expect(dismissals, 0);

    // The system back button, which still works under the overlay.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(dismissals, 1);
    expect(find.text('Home'), findsOneWidget);
  });
}

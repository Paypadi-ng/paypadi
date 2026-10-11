import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/gen/colors.gen.dart';
import 'package:paypadi/shared/widgets/app_avatar.dart';
import 'package:paypadi/shared/widgets/app_network_image.dart';

/// Network images never load in widget tests (every request gets a 400),
/// which is exactly the failure these widgets have to handle.
Future<void> pumpImage(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Center(child: child)));
  await tester.pumpAndSettle();
}

Finder fallbackTile() => find.byWidgetPredicate(
  (widget) => widget is ColoredBox && widget.color == AppColors.disabled,
);

void main() {
  testWidgets('a photo that fails to load shows a neutral tile of the same '
      'size instead of an error', (tester) async {
    await pumpImage(
      tester,
      AppNetworkImage(
        url: 'https://example.com/missing.png',
        size: 64,
        borderRadius: BorderRadius.circular(24),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(fallbackTile(), findsOneWidget);
    expect(tester.getSize(fallbackTile()), const Size.square(64));
  });

  testWidgets('an avatar whose photo fails to load falls back the same way', (
    tester,
  ) async {
    await pumpImage(
      tester,
      const AppAvatar(radius: 48, imageUrl: 'https://example.com/missing.png'),
    );

    expect(tester.takeException(), isNull);
    expect(fallbackTile(), findsOneWidget);
    expect(find.byType(ClipOval), findsOneWidget);
  });
}

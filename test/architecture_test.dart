import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps lib/ layered: core <- data <- shared <- features <- app.
///
/// A layer may import itself and the layers below it. Generated assets in
/// lib/gen/ sit below everything. The one way up is the app's navigation,
/// theme and session, which every screen uses; auto_route's generated router
/// imports every page, so that cycle is unavoidable.
///
/// Features don't import each other: state that several features need lives
/// in shared/, and features reach each other's screens through the router.
void main() {
  const below = <String, Set<String>>{
    'core': {'core', 'gen'},
    'data': {'core', 'gen', 'data'},
    'shared': {'core', 'gen', 'data', 'shared'},
    'features': {'core', 'gen', 'data', 'shared'},
    'app': {'core', 'gen', 'data', 'shared', 'features', 'app'},
  };
  const appServices = {
    'app/providers.dart',
    'app/router/router.gr.dart',
    'app/session/session_controller.dart',
    'app/session/session_unlocked.dart',
    'app/theme.dart',
  };
  final import = RegExp(
    r"^(?:import|export) 'package:paypadi/([^']+)'",
    multiLine: true,
  );
  final generated = RegExp(r'\.(g|freezed|gr|gen)\.dart$');

  test('no layer imports one above it, and features stay independent', () {
    final violations = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (generated.hasMatch(file.path)) continue;

      final path = file.path.substring('lib/'.length);
      final layer = path.split('/').first;
      final allowed = below[layer];
      // Entry points and Firebase options at the root may import anything.
      if (allowed == null) continue;

      for (final match in import.allMatches(file.readAsStringSync())) {
        final target = match.group(1)!;
        final targetLayer = target.split('/').first;
        if (allowed.contains(targetLayer)) continue;
        if (layer == 'features' &&
            targetLayer == 'features' &&
            target.split('/')[1] == path.split('/')[1]) {
          continue;
        }
        if (layer != 'core' &&
            layer != 'data' &&
            appServices.contains(target)) {
          continue;
        }
        violations.add('$path imports $target');
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}

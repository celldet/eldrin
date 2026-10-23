import 'dart:io';

import 'package:eldrin/ui/eldrin_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Plays through key moments of the game and captures store screenshots.
///
///   SHOT_DIR=store/screenshots/raw/ios flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/store_screenshots_test.dart -d DEVICE_ID
///
/// Debug builds only (it uses the debug "unlock without paying" button).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(Container());
    await tester.pumpWidget(EldrinApp(key: UniqueKey()));
    await tester.pumpAndSettle();
  }

  Future<void> cmd(WidgetTester tester, String text) async {
    await tester.showKeyboard(find.byType(TextField));
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
  }

  Future<void> run(WidgetTester tester, List<String> commands) async {
    for (final c in commands) {
      await cmd(tester, c);
    }
  }

  var surfaceConverted = false; // Android allows this only once per run

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    if (Platform.isAndroid && !surfaceConverted) {
      await binding.convertFlutterSurfaceToImage();
      surfaceConverted = true;
    }
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  const toWick = ['begin', 'w', 'n', 'w', 'take spectacles', 'e', 's', 'e', 'n'];

  testWidgets('store screenshots', (tester) async {
    // 1. Waking on the shore
    await launch(tester);
    // A few extra commands scroll the title banner fully out of view.
    await run(tester, ['begin', 'examine spire', 'examine sea', 'look']);
    await shot(tester, '01_shore');

    // 2. Meeting Wick
    await launch(tester);
    await run(tester, [...toWick, 'give spectacles to wick']);
    await shot(tester, '02_wick');

    // 3. Lighting the Beacon
    await launch(tester);
    await run(tester, [...toWick, 'give spectacles to wick', 'n', 'up', 'use oil on beacon', 'light beacon']);
    await shot(tester, '03_beacon');

    // 4. The riddle gate
    await launch(tester);
    await run(tester, [
      ...toWick, 'give spectacles to wick', 'n', 'up', 'use oil on beacon', 'light beacon',
      'down', 's', 's', 'e', 'e', 'e', 'examine gate',
    ]);
    await shot(tester, '04_gate');

    // 5. Paywall sheet, then the dark cistern after unlocking. (Starts from a
    // fresh launch: input typed after a screenshot is not delivered reliably.)
    await launch(tester);
    await run(tester, [
      ...toWick, 'give spectacles to wick', 'n', 'up', 'use oil on beacon', 'light beacon',
      'down', 's', 's', 'e', 'e', 'e', 'say night and day', 'east',
    ]);
    await tester.pumpAndSettle();
    await shot(tester, '06_paywall');
    await tester.tap(find.textContaining('Debug: unlock'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await run(tester, ['e', 'd']);
    await shot(tester, '05_cistern');
  });
}

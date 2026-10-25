import 'package:eldrin/game/entitlements.dart';
import 'package:eldrin/ui/eldrin_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Captures the unlock sheet with a fixed price for the App Store Connect
/// in-app purchase review screenshot.
///
///   SHOT_DIR=store/screenshots/raw/ios flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/iap_review_screenshot_test.dart -d DEVICE_ID
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iap review screenshot', (tester) async {
    await tester.pumpWidget(EldrinApp(entitlements: MemoryEntitlements()));
    await tester.pumpAndSettle();
    const commands = [
      'begin', 'w', 'n', 'w', 'take spectacles', 'e', 's', 'e', 'n',
      'give spectacles to wick', 'n', 'up', 'use oil on beacon', 'light beacon',
      'down', 's', 's', 'e', 'e', 'e', 'say night and day', 'east',
    ];
    for (final c in commands) {
      await tester.showKeyboard(find.byType(TextField));
      await tester.enterText(find.byType(TextField), c);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('iap_review_paywall');
  });
}

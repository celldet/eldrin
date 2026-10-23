import 'package:eldrin/ui/eldrin_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('title screen, begin, then move with the quick bar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const EldrinApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Type BEGIN'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'begin');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.textContaining('Waking Shore'), findsWidgets);

    await tester.tap(find.widgetWithText(ActionChip, 'N'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Driftwood Camp'), findsWidgets);
  });
}

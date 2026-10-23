import 'package:eldrin/game/engine.dart';
import 'package:eldrin/game/entitlements.dart';
import 'package:eldrin/game/save_store.dart';
import 'package:eldrin/ui/paywall_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('Free chapter ends at the Drowned Gate', () {
    test('solving the riddle works for free, walking through asks for the full game', () async {
      final e = await startedEngine(entitled: false);
      e.state.room = 'drowned_gate';

      expect(await run(e, ['say night and day']), contains('swings inward'));
      expect(e.takePaywallRequest(), isNull, reason: 'the riddle itself is free');

      final text = await run(e, ['east']);
      expect(text, contains('unlock the full game'));
      expect(e.state.room, 'drowned_gate');
      expect(e.takePaywallRequest(), 'east');
      expect(e.takePaywallRequest(), isNull, reason: 'request is consumed once');
    });

    test('a closed gate gives the normal message, not the paywall', () async {
      final e = await startedEngine(entitled: false);
      e.state.room = 'drowned_gate';
      expect(await run(e, ['east']), contains('answer'));
      expect(e.takePaywallRequest(), isNull);
    });

    test('owning the full game lets you through', () async {
      final e = await startedEngine(entitled: true);
      e.state.room = 'drowned_gate';
      await run(e, ['say night and day', 'east']);
      expect(e.state.room, 'sunken_plaza');
      expect(e.takePaywallRequest(), isNull);
    });

    test('everything before the gate is playable without buying', () async {
      final e = await startedEngine(entitled: false);
      final steps = [
        'w', 'n', 'w', 'take spectacles', 'e', 's', 'e', 'n', 'give spectacles to wick',
        'n', 'up', 'use oil on beacon', 'light beacon', 'down', 's', 's', 'e', 'e', 'e',
      ];
      for (final s in steps) {
        await e.submit(s);
      }
      expect(e.state.room, 'drowned_gate');
      expect(e.state.flags, contains('beacon_lit'));
    });

    test('the retry after unlocking gets the player through', () async {
      var owned = false;
      final e = GameEngine(
        world: loadTestWorld(),
        saveStore: MemorySaveStore(),
        isEntitled: (_) => owned,
      );
      await e.submit('begin');
      e.state.room = 'drowned_gate';
      await run(e, ['say night and day', 'east']);
      final retry = e.takePaywallRequest();
      expect(e.state.room, 'drowned_gate');

      owned = true; // the player buys it in the sheet
      await e.submit(retry!);
      expect(e.state.room, 'sunken_plaza');
    });
  });

  group('Paywall sheet', () {
    testWidgets('shows the price and unlocks on purchase', (tester) async {
      final ent = MemoryEntitlements();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: PaywallSheet(entitlements: ent)),
      ));

      expect(find.text('UNLOCK THE FULL GAME'), findsOneWidget);
      expect(find.textContaining(r'$3.99'), findsOneWidget);
      expect(find.text('Have a code?'), findsOneWidget);
      expect(find.text('Restore purchase'), findsOneWidget);

      await tester.tap(find.textContaining('Unlock full game'));
      await tester.pumpAndSettle();

      expect(ent.fullGame, isTrue);
      expect(find.text('THE DEEP IS OPEN'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('restore with nothing to restore says so', (tester) async {
      final ent = MemoryEntitlements();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: PaywallSheet(entitlements: ent)),
      ));
      await tester.tap(find.text('Restore purchase'));
      await tester.pumpAndSettle();
      expect(find.text('No previous purchase found.'), findsOneWidget);
      expect(ent.fullGame, isFalse);
    });
  });
}

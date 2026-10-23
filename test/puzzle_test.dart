import 'package:eldrin/game/engine.dart';
import 'package:eldrin/game/save_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('Puzzle: Wick, the oil and the Beacon', () {
    test('the reeds only yield to someone who follows their lean', () async {
      final e = await startedEngine();
      await run(e, ['west']);
      await run(e, ['south']);
      expect(e.state.room, 'reed1', reason: 'wrong way loops back');
      await run(e, ['north', 'west']);
      expect(e.state.room, 'heron_rest');
      expect(await run(e, ['take spectacles']), contains('Taken'));
    });

    test('spectacles -> oil -> beacon lit -> causeway opens', () async {
      final e = await startedEngine();
      await run(e, ['w', 'n', 'w', 'take spectacles', 'e', 's', 'e', 'n']);
      expect(e.state.room, 'driftwood');

      // Without the oil, the Beacon cannot be lit.
      await run(e, ['n', 'up']);
      expect(e.state.room, 'lighthouse_top');
      expect(await run(e, ['light beacon']), isNot(contains('catches')));
      await run(e, ['down', 'south']);

      expect(await run(e, ['give spectacles to wick']), contains('oil'));
      expect(e.state.has('oil_flask'), isTrue);
      expect(e.state.has('spectacles'), isFalse);

      // The tide still blocks the causeway.
      await run(e, ['s', 'e', 'e']);
      expect(e.state.room, 'tidal_flats');
      await run(e, ['w', 'n', 'n', 'up']);
      expect(await run(e, ['use oil on beacon']), contains('oil'));
      expect(e.state.flags, contains('beacon_oiled'));
      expect(await run(e, ['light beacon']), contains('catches'));
      expect(e.state.flags, contains('beacon_lit'));

      await run(e, ['down', 's', 's', 'e', 'e']);
      expect(e.state.room, 'bone_bridge');
    });
  });

  group('Puzzle: the riddle gate', () {
    test('wrong answers do nothing, the right one opens it', () async {
      final e = await startedEngine();
      e.state.room = 'drowned_gate';
      e.state.flags.add('beacon_lit');
      expect(await run(e, ['east']), contains('answer'));
      await run(e, ['say banana']);
      expect(e.state.flags, isNot(contains('gate_open')));
      expect(await run(e, ['say night and day']), contains('swings inward'));
      expect(e.state.flags, contains('gate_open'));
      await run(e, ['east']);
      expect(e.state.room, 'sunken_plaza');
    });
  });

  group('Puzzle: grappling hook', () {
    test('combining rope and hook, then crossing the chasm', () async {
      final e = await startedEngine();
      e.state.itemLocations['rope'] = kHeld;
      e.state.itemLocations['hook'] = kHeld;
      e.state.room = 'ash_chasm';
      e.state.light = 20;

      expect(await run(e, ['east']), contains('too wide'));
      await run(e, ['use grapple on pillar']);
      expect(e.state.flags, isNot(contains('chasm_crossed')));

      expect(await run(e, ['combine rope with hook']), contains('grappling hook'));
      expect(e.state.has('grapple'), isTrue);
      expect(e.state.has('rope'), isFalse);

      expect(await run(e, ['use grapple on pillar']), contains('bridge'));
      await run(e, ['east']);
      expect(e.state.room, 'ember_forge');
    });
  });

  group('Puzzle: the choir bells', () {
    test('wrong order resets, Heart-Root-Sky opens the door', () async {
      final e = await startedEngine();
      e.state.room = 'choir_hall';

      expect(await run(e, ['ring sky bell']), contains('unravels'));
      expect(await run(e, ['ring heart bell']), contains('waiting'));
      expect(await run(e, ['ring sky bell']), contains('unravels'));
      expect(e.state.flags, isNot(contains('choir_open')));
      expect(await run(e, ['east']), contains('sealed'));

      await run(e, ['ring heart bell', 'ring root bell']);
      expect(await run(e, ['ring sky bell']), contains('swings wide'));
      expect(e.state.flags, contains('choir_open'));
      await run(e, ['east']);
      expect(e.state.room, 'hush_sanctum');
    });
  });

  group('Puzzle: the Lantern of Ember is too hot to hold', () {
    test('needs the tongs', () async {
      final e = await startedEngine();
      e.state.room = 'ember_forge';
      expect(await run(e, ['take lantern']), contains('heat'));
      expect(e.state.has('lantern_ember'), isFalse);
      e.state.itemLocations['tongs'] = kHeld;
      await run(e, ['take lantern']);
      expect(e.state.has('lantern_ember'), isTrue);
    });
  });

  group('Light', () {
    test('dark rooms drain light and running out is forgiving', () async {
      final e = await startedEngine();
      e.state.room = 'flooded_market';
      final before = e.state.light;
      await run(e, ['down']);
      expect(e.state.light, before - 1);

      e.state.light = 1;
      final text = await run(e, ['east', 'west']);
      expect(e.state.room, isNot('cistern'));
      expect(e.state.light, greaterThan(0));
      expect(text, anyOf(contains('safe'), contains('Cistern')));
    });

    test('resting in a glowing place refills the lamp', () async {
      final e = await startedEngine();
      e.state.room = 'glow_cavern';
      e.state.light = 3;
      await run(e, ['rest']);
      expect(e.state.light, e.maxLight);
    });
  });

  group('Save / load', () {
    test('round trip restores state', () async {
      final store = MemorySaveStore();
      final e = await startedEngine(store: store);
      await run(e, ['w', 'n', 'w', 'take spectacles', 'save']);
      final score = e.state.score;

      final e2 = await startedEngine(store: store);
      await run(e2, ['load']);
      expect(e2.state.room, 'heron_rest');
      expect(e2.state.has('spectacles'), isTrue);
      expect(e2.state.score, score);
    });
  });

  group('Ending', () {
    test('placing all three lanterns offers a choice and ranks the player', () async {
      final e = await startedEngine();
      e.state.room = 'heart';
      for (final id in ['lantern_tide', 'lantern_ember', 'lantern_hush']) {
        e.state.itemLocations[id] = kHeld;
      }
      await run(e, ['put lantern of tide on altar', 'put lantern of ember on altar']);
      expect(e.phase, Phase.playing);
      final out = await run(e, ['put lantern of hush on altar']);
      expect(out, contains('WORLD'));
      expect(e.phase, Phase.choice);
      final end = await run(e, ['world']);
      expect(end, contains('Rank:'));
      expect(e.phase, Phase.ended);
    });
  });

  test('unknown commands get a response mentioning the word', () async {
    final e = await startedEngine();
    final out = await run(e, ['frobnicate']);
    expect(out, contains('frobnicate'));
  });

  test('walkthrough from start to finish', () async {
    final e = await startedEngine();
    final steps = <String>[
      // Wick's spectacles, Pell's rope
      'w', 'n', 'w', 'take spectacles', 'e', 's', 'e', 'n',
      'give spectacles to wick',
      'e', 'e', 'take apple', 'give apple to pell', 'w', 'w',
      // Beacon
      'n', 'up', 'use oil on beacon', 'light beacon', 'down', 's', 's',
      // Gate and city
      'e', 'e', 'e', 'say night and day', 'e',
      'bow', 'e', 'take hook', 'combine rope and hook', 'd', 'take wheel', 'e', 'rest',
      'e', 'use shard on pedestal', 'e', 'take tongs', 'e', 'use grapple on pillar', 'e',
      'take lantern',
      // Back for Tide and the ledger
      'w', 'w', 'w', 'w', 'w', 'u', 'w', 'n', 'use wheel on valve', 'n', 'take lantern', 's', 's',
      's', 'take ledger', 'read ledger', 'n',
      // To the choir
      'w', 'w', 'w', 'w', 'n', 'e', 'e', 'n', 'n', 'e',
      'ring heart bell', 'ring root bell', 'ring sky bell', 'e', 'take lantern', 'w', 'w', 'n',
      'put lantern of tide on altar', 'put lantern of ember on altar', 'put lantern of hush on altar',
    ];
    for (final s in steps) {
      await e.submit(s);
    }
    expect(e.phase, Phase.choice, reason: 'room: ${e.state.room}, flags: ${e.state.flags}');
    await e.submit('world');
    expect(e.phase, Phase.ended);
    expect(e.state.score, greaterThan(100));
  });
}

const kHeld = 'inv';

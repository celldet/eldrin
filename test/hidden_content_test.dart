import 'package:eldrin/game/engine.dart';
import 'package:eldrin/game/save_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  test('phrase typed in the dark cistern', () async {
    final e = await startedEngine();
    e.state.room = 'cistern';
    expect(e.state.flags, isNot(contains('alcove_open')));
    await run(e, ['say i am not afraid']);
    expect(e.state.flags, contains('alcove_open'));
    await run(e, ['west']);
    expect(e.state.room, 'whisper_alcove');
  });

  test('phrase in a lit room does nothing special', () async {
    final e = await startedEngine();
    await run(e, ['i am not afraid']);
    expect(e.state.flags, isNot(contains('alcove_open')));
  });

  test('repeated examining', () async {
    final e = await startedEngine();
    final before = e.state.score;
    await run(e, ['x pebble', 'x pebble', 'x pebble', 'x pebble']);
    expect(e.state.score, before);
    await run(e, ['x pebble']);
    expect(e.state.score, before + 3);
  });

  test('streak is broken by other commands', () async {
    final e = await startedEngine();
    final before = e.state.score;
    await run(e, ['x pebble', 'x pebble', 'x pebble', 'look', 'x pebble', 'x pebble']);
    expect(e.state.score, before);
  });

  test('title screen word', () async {
    final e = GameEngine(
      world: loadTestWorld(),
      saveStore: MemorySaveStore(),
      isEntitled: (_) => true,
    );
    await e.submit('frumbleglass');
    await e.submit('begin');
    await e.submit('in');
    expect(e.state.room, 'unwritten');
  });

  test('real-world time of day', () async {
    final night = await startedEngine(now: DateTime(2026, 1, 1, 23, 30));
    night.state.room = 'moon_well';
    expect(await run(night, ['look']), contains('second moon'));
    await run(night, ['examine well']);
    expect(night.state.has('moon_drop'), isTrue);

    final day = await startedEngine(now: DateTime(2026, 1, 1, 13));
    day.state.room = 'moon_well';
    expect(await run(day, ['look']), isNot(contains('second moon')));
    await run(day, ['examine well']);
    expect(day.state.has('moon_drop'), isFalse);
  });

  test('pickup order', () async {
    final e = await startedEngine();
    e.state.room = 'tidal_flats';
    await run(e, ['take glass']);
    e.state.room = 'heron_rest';
    await run(e, ['take feather']);
    e.state.room = 'driftwood';
    await run(e, ['take spoon']);
    expect(e.state.flags, contains('attic_open'));
    await run(e, ['up']);
    expect(e.state.room, 'attic');
  });

  test('wrong pickup order does not trigger', () async {
    final e = await startedEngine();
    e.state.room = 'driftwood';
    await run(e, ['take spoon']);
    e.state.room = 'heron_rest';
    await run(e, ['take feather']);
    e.state.room = 'tidal_flats';
    await run(e, ['take glass']);
    expect(e.state.flags, isNot(contains('attic_open')));
  });

  test('manners with an NPC', () async {
    final e = await startedEngine();
    e.state.room = 'driftwood';
    final plain = await run(e, ['talk to wick']);
    expect(plain, isNot(contains('Luck')));
    expect(await run(e, ['talk to wick please']), contains('Please!'));
    expect(e.state.has('luck_coin'), isTrue);
    // only once
    expect(await run(e, ['please']), contains('Still polite'));
  });

  test('dancing among the gods', () async {
    final e = await startedEngine();
    e.state.room = 'gods_garden';
    final before = e.state.score;
    await run(e, ['dance']);
    expect(e.state.score, before + 2);
  });

  test('old cave words get a polite brush-off', () async {
    final e = await startedEngine();
    expect(await run(e, ['xyzzy']), contains('different cave'));
  });
}

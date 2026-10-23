import 'package:eldrin/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = CommandParser();

  group('directions', () {
    test('single letters and words map to canonical directions', () {
      for (final (input, dir) in [
        ('n', 'north'),
        ('S', 'south'),
        ('east', 'east'),
        ('w', 'west'),
        ('u', 'up'),
        ('d', 'down'),
      ]) {
        final c = parser.parse(input);
        expect(c.verb, 'go', reason: input);
        expect(c.direction, dir, reason: input);
      }
    });

    test('"go north", "walk west" and "head up" work', () {
      expect(parser.parse('go north').direction, 'north');
      expect(parser.parse('walk west').direction, 'west');
      expect(parser.parse('head up').direction, 'up');
      expect(parser.parse('go in').direction, 'in');
    });

    test('implied directions', () {
      expect(parser.parse('leave').direction, 'out');
      expect(parser.parse('climb up').direction, 'up');
      expect(parser.parse('climb the stairs').direction, 'up');
    });
  });

  group('verb synonyms', () {
    test('take synonyms', () {
      for (final v in ['take', 'grab', 'get', 'snag', 'pick up']) {
        final c = parser.parse('$v lamp');
        expect(c.verb, 'take', reason: v);
        expect(c.noun, 'lamp', reason: v);
      }
      expect(parser.parse('pick lamp up').noun, 'lamp');
    });

    test('look is the room, look at is examine', () {
      expect(parser.parse('look').verb, 'look');
      expect(parser.parse('l').verb, 'look');
      final c = parser.parse('look at the statue');
      expect(c.verb, 'examine');
      expect(c.noun, 'statue');
      expect(parser.parse('look statue').verb, 'examine');
      expect(parser.parse('x statue').verb, 'examine');
    });

    test('inventory', () {
      expect(parser.parse('i').verb, 'inventory');
      expect(parser.parse('inv').verb, 'inventory');
      expect(parser.parse('inventory').verb, 'inventory');
    });
  });

  group('objects and prepositions', () {
    test('articles are removed', () {
      expect(parser.parse('take the brass key').noun, 'brass key');
      expect(parser.parse('examine a rusty hook').noun, 'rusty hook');
    });

    test('use X on Y', () {
      final c = parser.parse('use key on door');
      expect(c.verb, 'use');
      expect(c.noun, 'key');
      expect(c.preposition, 'on');
      expect(c.indirect, 'door');
    });

    test('give X to Y, combine X and Y', () {
      final g = parser.parse('give the apple to pell');
      expect(g.verb, 'give');
      expect(g.noun, 'apple');
      expect(g.indirect, 'pell');
      final c = parser.parse('combine rope and hook');
      expect(c.verb, 'combine');
      expect(c.noun, 'rope');
      expect(c.indirect, 'hook');
      expect(parser.parse('tie rope to hook').verb, 'combine');
    });

    test('talk to and ask about', () {
      final t = parser.parse('talk to wick');
      expect(t.verb, 'talk');
      expect(t.noun, 'wick');
      final a = parser.parse('ask wick about the lanterns');
      expect(a.verb, 'talk');
      expect(a.noun, 'wick');
      expect(a.indirect, 'lanterns');
    });

    test('multi-word nouns survive', () {
      expect(parser.parse('take lantern of tide').noun, 'lantern of tide');
      expect(parser.parse('ring the heart bell').noun, 'heart bell');
    });

    test('punctuation and case are ignored', () {
      final c = parser.parse('  TAKE   the Lamp!!! ');
      expect(c.verb, 'take');
      expect(c.noun, 'lamp');
    });
  });

  group('unknown input', () {
    test('unrecognised verb becomes unknown with the word kept', () {
      final c = parser.parse('frobnicate the widget');
      expect(c.isUnknown, isTrue);
      expect(c.unknownWord, 'frobnicate');
    });

    test('empty input', () {
      expect(parser.parse('   ').isEmpty, isTrue);
      expect(parser.parse('!!!').isEmpty, isTrue);
    });

    test('verb with no object parses without error', () {
      final c = parser.parse('take');
      expect(c.verb, 'take');
      expect(c.noun, isNull);
    });
  });
}

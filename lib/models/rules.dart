import 'common.dart';

/// A data-driven puzzle rule: "verb [item] [on target]" with conditions and
/// effects. Rules for the same command are tried in file order; the first whose
/// [requires] hold wins.
class Interaction {
  const Interaction({
    required this.id,
    required this.verbs,
    this.item,
    this.target,
    this.room,
    this.implicit = false,
    this.requires = const [],
    this.failText,
    required this.text,
    this.effects = const [],
  });

  final String id;
  final List<String> verbs;
  final String? item;
  final String? target;
  final String? room;

  /// If true, the rule also fires when the player names no object at all
  /// ("bow" instead of "bow to statue").
  final bool implicit;
  final List<String> requires;
  final String? failText;
  final String text;
  final List<String> effects;

  factory Interaction.fromJson(Map<String, dynamic> json) => Interaction(
        id: json['id'] as String,
        verbs: readStrings(json['verbs']),
        item: json['item'] as String?,
        target: json['target'] as String?,
        room: json['room'] as String?,
        implicit: json['implicit'] as bool? ?? false,
        requires: readStrings(json['requires']),
        failText: json['failText'] as String?,
        text: json['text'] as String,
        effects: readStrings(json['effects']),
      );
}

/// Reacts to something the player says or types verbatim.
class PhraseRule {
  const PhraseRule({
    required this.phrases,
    this.room,
    this.darkOnly = false,
    this.requires = const [],
    required this.text,
    this.failText,
    this.effects = const [],
  });

  final List<String> phrases;
  final String? room;

  /// Only fires while the player is in a dark room.
  final bool darkOnly;
  final List<String> requires;
  final String text;
  final String? failText;
  final List<String> effects;

  factory PhraseRule.fromJson(Map<String, dynamic> json) => PhraseRule(
        phrases: readStrings(json['phrases']),
        room: json['room'] as String?,
        darkOnly: json['darkOnly'] as bool? ?? false,
        requires: readStrings(json['requires']),
        text: json['text'] as String,
        failText: json['failText'] as String?,
        effects: readStrings(json['effects']),
      );
}

/// Picking up [order] consecutively triggers [text] and [effects].
class PickupSequence {
  const PickupSequence({
    required this.order,
    required this.text,
    this.requires = const [],
    this.effects = const [],
  });

  final List<String> order;
  final String text;
  final List<String> requires;
  final List<String> effects;

  factory PickupSequence.fromJson(Map<String, dynamic> json) => PickupSequence(
        order: readStrings(json['order']),
        text: json['text'] as String,
        requires: readStrings(json['requires']),
        effects: readStrings(json['effects']),
      );
}

/// A word typed at the title screen that changes the next journey.
class TitleWord {
  const TitleWord({required this.word, required this.text, this.effects = const []});

  final String word;
  final String text;
  final List<String> effects;

  factory TitleWord.fromJson(Map<String, dynamic> json) => TitleWord(
        word: json['word'] as String,
        text: json['text'] as String,
        effects: readStrings(json['effects']),
      );
}

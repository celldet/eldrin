import 'common.dart';

/// What happens when the player uses an item on its own ("use moss").
class UseAlone {
  const UseAlone({
    this.requires = const [],
    required this.text,
    this.failText,
    this.effects = const [],
  });

  final List<String> requires;
  final String text;
  final String? failText;
  final List<String> effects;

  static UseAlone? fromJson(Object? json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return UseAlone(
      requires: readStrings(m['requires']),
      text: m['text'] as String,
      failText: m['failText'] as String?,
      effects: readStrings(m['effects']),
    );
  }
}

class ItemDef {
  const ItemDef({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.desc,
    this.start = 'void',
    this.portable = true,
    this.extras = const [],
    this.takeRequires = const [],
    this.takeBlocked,
    this.takeText,
    this.onTake = const [],
    this.useAlone,
    this.readText,
    this.streak,
  });

  final String id;
  final String name;
  final List<String> aliases;
  final String desc;

  /// A room id, `inv` (starts carried) or `void` (not yet in the world).
  final String start;
  final bool portable;
  final List<Conditional> extras;
  final List<String> takeRequires;
  final String? takeBlocked;
  final String? takeText;
  final List<String> onTake;
  final UseAlone? useAlone;
  final String? readText;
  final Streak? streak;

  List<String> get names => [name, ...aliases];

  String get withArticle {
    final first = name.isEmpty ? '' : name[0].toLowerCase();
    return 'aeiou'.contains(first) ? 'an $name' : 'a $name';
  }

  factory ItemDef.fromJson(Map<String, dynamic> json) => ItemDef(
        id: json['id'] as String,
        name: json['name'] as String,
        aliases: readStrings(json['aliases']),
        desc: json['desc'] as String,
        start: json['start'] as String? ?? 'void',
        portable: json['portable'] as bool? ?? true,
        extras: Conditional.list(json['extras']),
        takeRequires: readStrings(json['takeRequires']),
        takeBlocked: json['takeBlocked'] as String?,
        takeText: json['takeText'] as String?,
        onTake: readStrings(json['onTake']),
        useAlone: UseAlone.fromJson(json['useAlone']),
        readText: json['readText'] as String?,
        streak: Streak.fromJson(json['streak']),
      );
}

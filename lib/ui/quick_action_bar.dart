import 'package:flutter/material.dart';

/// Two rows of chips: instant commands, and verbs that prefill the input.
class QuickActionBar extends StatelessWidget {
  const QuickActionBar({
    super.key,
    required this.exits,
    required this.onCommand,
    required this.onPrefill,
  });

  /// Directions currently available; highlighted in the bar.
  final List<String> exits;
  final ValueChanged<String> onCommand;
  final ValueChanged<String> onPrefill;

  static const _directions = <(String label, String command, String exit)>[
    ('N', 'north', 'north'),
    ('S', 'south', 'south'),
    ('E', 'east', 'east'),
    ('W', 'west', 'west'),
    ('Up', 'up', 'up'),
    ('Down', 'down', 'down'),
    ('In', 'in', 'in'),
    ('Out', 'out', 'out'),
  ];

  static const _cardinals = {'north', 'south', 'east', 'west'};

  static const _instant = <(String label, String command)>[
    ('Look', 'look'),
    ('Inv', 'inventory'),
    ('Rest', 'rest'),
    ('Hint', 'hint'),
    ('Score', 'score'),
    ('Save', 'save'),
    ('Load', 'load'),
  ];

  static const _prefills = <(String label, String text)>[
    ('Take', 'take '),
    ('Examine', 'examine '),
    ('Use', 'use '),
    ('Give', 'give '),
    ('Talk', 'talk to '),
    ('Open', 'open '),
    ('Say', 'say '),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row([
          for (final d in _directions)
            if (exits.contains(d.$3) || _cardinals.contains(d.$3))
              _chip(context, d.$1, () => onCommand(d.$2), highlighted: exits.contains(d.$3)),
          for (final a in _instant) _chip(context, a.$1, () => onCommand(a.$2)),
        ]),
        _row([
          for (final p in _prefills)
            _chip(context, p.$1, () => onPrefill(p.$2), outlineColor: scheme.secondary),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> children) => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          children: children,
        ),
      );

  Widget _chip(
    BuildContext context,
    String label,
    VoidCallback onTap, {
    bool highlighted = false,
    Color? outlineColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        backgroundColor: highlighted ? scheme.primary.withValues(alpha: 0.25) : null,
        side: BorderSide(
          color: highlighted
              ? scheme.primary
              : (outlineColor ?? scheme.onSurface).withValues(alpha: 0.35),
        ),
        labelStyle: TextStyle(
          fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

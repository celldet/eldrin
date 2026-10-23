import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/entitlements.dart';

/// Shows the unlock sheet. Completes when it is dismissed; check
/// [Entitlements.fullGame] afterwards to see whether the player unlocked.
Future<void> showPaywall(BuildContext context, Entitlements entitlements) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PaywallSheet(entitlements: entitlements),
  );
}

class PaywallSheet extends StatelessWidget {
  const PaywallSheet({super.key, required this.entitlements});

  final Entitlements entitlements;

  static const _perks = [
    'The drowned city: market, archive and cathedral',
    'The Ember forge and the Crystal Hall',
    'All three Lanterns and the finale',
    'Every future update to the story',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: entitlements,
        builder: (context, _) {
          final unlocked = entitlements.fullGame;
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  unlocked ? 'THE DEEP IS OPEN' : 'UNLOCK THE FULL GAME',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                if (unlocked)
                  const Text(
                    'Thank you for supporting Eldrin. The way is open.',
                    textAlign: TextAlign.center,
                  )
                else ...[
                  const Text(
                    'You have reached the end of the free chapter. One purchase unlocks the rest of the Hollowmere:',
                  ),
                  const SizedBox(height: 8),
                  for (final perk in _perks)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('•  $perk'),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'One-time purchase. No ads. No subscription.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                if (unlocked)
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continue'),
                  )
                else ...[
                  FilledButton(
                    onPressed: entitlements.busy || !entitlements.storeAvailable
                        ? null
                        : entitlements.buy,
                    child: entitlements.busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(entitlements.price == null
                            ? 'Unlock full game'
                            : 'Unlock full game  ·  ${entitlements.price}'),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: entitlements.busy ? null : entitlements.restore,
                        child: const Text('Restore purchase'),
                      ),
                      TextButton(
                        onPressed: entitlements.busy ? null : entitlements.redeemCode,
                        child: const Text('Have a code?'),
                      ),
                    ],
                  ),
                  if (kDebugMode)
                    TextButton(
                      onPressed: entitlements.debugUnlock,
                      child: const Text('Debug: unlock without paying'),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Not now'),
                  ),
                ],
                if (entitlements.message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    entitlements.message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

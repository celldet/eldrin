# Eldrin

*The Lanterns of the Deep.* A text adventure for iOS and Android, built with Flutter.

You wake on a cold shore in the Hollowmere, a realm of drowned cities, glowing ruins and forgotten
gods. Three Lanterns (Tide, Ember and Hush) once kept the deep lit. Find them, carry them to the
Heart of the Hollowmere, and bring back the light.

## Playing

Type short commands or tap the buttons under the log.

| Command | Examples |
| --- | --- |
| Move | `north`, `n`, `go west`, `up`, `down`, `in`, `out` |
| Look | `look`, `examine statue`, `x statue`, `look at statue` |
| Items | `take lamp`, `grab key`, `drop rope`, `inventory` (`i`) |
| Use | `use key on door`, `give apple to pell`, `combine rope and hook` |
| People | `talk to wick`, `ask pell about rope` |
| Other | `open`, `read`, `ring`, `bow`, `sing`, `say <words>` |
| Light | `rest` recovers lamp light |
| Meta | `hint`, `score`, `save`, `load`, `help` |

**Light:** walking through dark places drains your lamp. Rest in glowing places to refill it fully.
If it runs out you are not hurt; you are simply carried back to safety.

## Requirements

- Flutter 3.x stable (Dart 3.x), see <https://docs.flutter.dev/get-started/install>
- Android Studio with an Android SDK and an emulator (for Android)
- Xcode with an iOS simulator (macOS only, for iOS)

Check your setup with `flutter doctor`.

## Setup

```sh
flutter pub get
flutter test          # parser, puzzle and world-data tests
```

### Run on an Android emulator

1. Android Studio -> Device Manager -> create / start a virtual device (or `flutter emulators --launch <id>`).
2. `flutter devices` should list it.
3. `flutter run` (add `-d <device-id>` if more than one device is connected).

### Run on an iOS simulator (macOS)

1. `open -a Simulator` (or `flutter emulators --launch apple_ios_simulator`).
2. `flutter run -d ios` (or `-d <simulator-id>` from `flutter devices`).
3. First build only: if CocoaPods complains, run `cd ios && pod install && cd ..`.

### Release builds

```sh
flutter build apk --release        # Android
flutter build ios --release        # iOS (needs signing configured in Xcode)
```

## Project structure

```
lib/
  main.dart               entry point
  models/                 plain data classes: rooms, items, NPCs, rules, world, game state
  data/                   world loader (assets -> models) and static text (help, rank titles, replies)
  parser/                 tokenizer, vocabulary (synonyms) and command parser
  game/                   engine, condition/effect evaluator, bell puzzle, save storage
  ui/                     single game screen, quick-action bar, themes
assets/world/
  rooms.json              the room graph, scenery, exits, description variants
  items.json              items and what they do
  npcs.json               characters and their dialogue
  rules.json              puzzle rules, riddle answers, hints
  secrets.json            optional extra content (see "Extending")
test/                     parser, puzzle, world-data and widget tests
```

## Extending the world

All content is data. No Dart changes are needed for new rooms, items, NPCs or most puzzles.

### Add a room

1. Add an object to `rooms[]` in `assets/world/rooms.json`:

   ```json
   {
     "id": "salt_cellar",
     "name": "The Salt Cellar",
     "desc": "Base description.",
     "dark": false,
     "glow": false,
     "variants": [{"when": ["flag:cellar_flooded"], "text": "Extra text when the flag is set."}],
     "exits": {"up": "archive"},
     "scenery": [{"id": "barrel", "names": ["barrel", "cask"], "desc": "A barrel."}]
   }
   ```

2. Link it from an existing room by adding an exit there (`"down": "salt_cellar"`). An exit can also be an
   object: `{"to": "salt_cellar", "requires": ["has:key"], "blocked": "Locked.", "visibleIf": ["flag:x"], "text": "..."}`.
3. Run `flutter test`. `world_data_test.dart` checks that exits, items, flags and rule references are valid.

### Add an item or NPC

Add to `items.json` (`start` is a room id, `"inv"` or `"void"`) or `npcs.json`. Items can be taken, combined
and used through rules; NPCs get ordered dialogue `lines`, `topics` for `ask ... about`, and a `fallback`.

### Add a puzzle

Add an entry to `interactions` in `rules.json`: the verbs, the item and/or target, `requires` conditions,
response `text` and `effects`.

Conditions: `flag:x`, `has:item`, `here:item`, `npc:id`, `room:id`, `visited:room`, `light<N`, `light>N`,
`time:night`; prefix `!` to negate and use `a|b` for "either".
Effects: `set:flag`, `clear:flag`, `give:item`, `remove:item`, `spawn:item`, `place:item@room`, `score:N`,
`light:+N`, `light:full`, `move:room`.

## In-app purchase

The first chapter is free. It ends at the Drowned Gate, and a single one-time purchase ("full game")
unlocks the rest. There are no ads and no subscriptions.

- **Product id:** `eldrin_full_game`, in `lib/game/entitlements.dart` (`Entitlements.fullGameId`).
  Create it as a **non-consumable** in App Store Connect and as a **one-time (managed) product**
  in Google Play Console, with the same id.
- **Where the gate is:** a room exit in `assets/world/rooms.json` carries `"entitlement": "full"`
  (see the Drowned Gate's east exit). Any exit can be gated the same way.
- **Restore and codes:** the unlock sheet has *Restore purchase* and *Have a code?* buttons. Codes are
  created in the stores' own consoles (Apple offer codes, Google Play promo codes) and redeemed through
  the platform's redemption screen. The game never validates codes itself.
- **Testing:** debug builds show an extra *unlock without paying* button on the sheet. To test real
  purchases, use a StoreKit configuration in Xcode (iOS) or a licence-testing account and an uploaded
  internal-test build (Android).

## Saving

`save` and `load` (or the buttons) store the game in the device's local key-value storage
(`shared_preferences`). There is one save slot.

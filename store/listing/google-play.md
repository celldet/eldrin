# Google Play listing: Eldrin

Everything to paste into Play Console. Items in **[brackets]** are yours to fill in.

## Main store listing
| Field | Value |
| --- | --- |
| App name (30) | Eldrin: Lanterns of the Deep |
| Short description (80) | Find the three Lanterns of the Deep in a drowned realm. Type or tap. No ads. |
| Category | Game > Adventure |
| Tags | Adventure, Puzzle, Story rich, Text |
| Contact email | support@playeldrin.com |
| Website | https://playeldrin.com |
| Privacy policy | https://playeldrin.com/privacy |
| Default language | English (United States) |

**Full description (4000)**
```
You wake on a cold grey shore with a small brass lamp in your hand and no memory of who you were.

Welcome to the Hollowmere: a shifting realm of drowned cities, glowing ruins and forgotten gods. Three Lanterns once kept the deep lit. Now they are lost, and the dark is growing. Find the Lanterns of Tide, Ember and Hush, carry them to the Heart of the Hollowmere, and bring back the light.

Eldrin is a classic text adventure, written from scratch for your phone. Type short commands like "go north", "take lamp" or "use key on door", or tap the quick buttons. The game understands plenty of synonyms and answers nonsense with a wink instead of an error.

WHAT YOU'LL FIND
• More than 30 places to explore, from reed marshes and a broken lighthouse to a drowned cathedral and an ember forge
• Puzzles that reward observation, the right item at the right moment, and a little lateral thinking
• Strange characters whose words change with what you have done and what you carry
• A lamp whose light is precious: dark places drain it, glowing places restore it. It is forgiving by design, so running out never ends your journey
• Descriptions that change as the world changes around you
• A score and a rank at the end, shaped by what you discover and the choices you make
• A built-in hint command when you are stuck
• Save and load whenever you like
• Light and dark themes with a retro, readable typeface

FREE TO START
The first chapter is free, from the shore to the Drowned Gate. One one-time purchase unlocks the rest of the story and every future update. No ads. No subscriptions.

Perfect for anyone who loves interactive fiction, cosy puzzle games, or the simple pleasure of a good story told in words.
```

## Graphics
| Asset | File | Spec |
| --- | --- | --- |
| App icon | `store/graphics/android/icon-512.png` | 512 x 512 PNG |
| Feature graphic | `store/graphics/android/feature-graphic-1024x500.png` | 1024 x 500 |
| Phone screenshots | `store/graphics/android/phone-screenshots/01..05` | 1080 x 1920 (min 2, max 8) |

Tablet screenshots are optional and only needed if you want to be featured on tablets.

## App content
| Section | Answer |
| --- | --- |
| Privacy policy | URL above |
| Ads | **No**, the app contains no ads |
| App access | All functionality is available without special access. The free chapter is open; the rest is behind an in-app purchase. For reviewers, add a note with the route to the paywall (below), or give them a promo code |
| Target audience | **13 and older** is the simplest choice. Selecting younger ages makes the app subject to Google's Families policies |
| Content rating (IARC) | Category: Game. Answer **No** to violence, fear, sexuality, language, controlled substances, gambling and user interaction. Digital purchases: **Yes**. Expected result: **Everyone** (confirm in the questionnaire) |
| Data safety | **No data collected, no data shared.** Saved games and settings stay on the device; purchases are processed by Google Play. Security: data is not sent anywhere. Update if you add analytics or crash reporting |
| News / COVID / Government / Financial | Not applicable |

## In-app product
| Field | Value |
| --- | --- |
| Product type | One-time product (managed, non-consumable) |
| Product ID | `eldrin_full_game` (must match `Entitlements.fullGameId` in the app) |
| Name | Full Game |
| Description | Unlock the rest of the story and all future updates. One-time, no subscription. |
| Price | **[your choice]**; a typical starting point is USD 3.99, with local prices auto-converted |

**Promo codes for influencers:** Play Console > Grow users > Promotions > Promo codes > one-time products.
Recipients redeem through the Play Store (the game's "Have a code?" button opens the redeem page). Check
Google's current per-quarter limits when you create them.

**Reviewer note (App access):**
```
Type these commands in order to reach the purchase screen: begin, w, n, w, take spectacles, e, s, e, n,
give spectacles to wick, n, up, use oil on beacon, light beacon, down, s, s, e, e, e, say night and day, east.
```

## What's new
> Welcome to the Hollowmere! This is the first release of Eldrin.

## Release checklist
1. **Create an upload keystore** and wire it into `android/app/build.gradle.kts` (the release build is
   currently signed with the debug key, which Play rejects).
2. **Application ID:** `app.eldrin.eldrin`. It can never be changed after the first upload. Change it now if you
   want something different (for example your own domain).
3. `flutter build appbundle --release`, upload the `.aab` to an Internal testing track first.
4. Enrol in **Play App Signing** when prompted.
5. Add licence testers (Settings > License testing) to test purchases on the internal track.
6. New personal developer accounts must run a **closed test with at least 12 testers for 14 days** before
   production access. Check the current requirement in Play Console.

# App Store listing: Eldrin

Everything to paste into App Store Connect. Items in **[brackets]** are yours to fill in.
Character counts are within Apple's limits (checked in `copy.json`).

## App information
| Field | Value |
| --- | --- |
| Name (30) | Eldrin: Lanterns of the Deep |
| Subtitle (30) | A drowned-world text adventure |
| Bundle ID | `app.eldrin.eldrin` |
| SKU | `eldrin-ios-1` (any unique string) |
| Primary category | Games |
| Game subcategories | Adventure, Puzzle |
| Content rights | You own or have licensed all content: **Yes** (everything is original) |
| Devices | iPhone only (iPad support is switched off in the Xcode project) |
| Minimum iOS | 15.0 |

## Pricing and availability
- **Price:** Free, with one in-app purchase (below).
- Availability: all territories, unless you want to limit.

## Version 1.0.0 page
**Promotional text (170)** (editable any time without a new build)
> Wake in a drowned realm of forgotten gods. Find the three Lanterns of the Deep and bring back the light. The first chapter is free, and there are no ads.

**Description (4000)**
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

**Keywords (100)**
```
interactive fiction,puzzle,fantasy,story,retro,mystery,explore,quest,riddles,parser,hollowmere
```
Keywords already in the name or subtitle are indexed automatically, so they are left out. Do not add other
apps' names or trademarks.

**What's New**
> Welcome to the Hollowmere! This is the first release of Eldrin.

| Field | Value |
| --- | --- |
| Support URL | https://playeldrin.com/support |
| Marketing URL (optional) | https://playeldrin.com |
| Privacy Policy URL | https://playeldrin.com/privacy |
| Copyright | 2026 ReibLAR LLC |

## Screenshots
Upload `store/graphics/ios/screenshots-6.9in/*.png` (1320 x 2868) to the **6.9-inch** iPhone slot, in order
`01` to `05`. App Store Connect scales them for smaller iPhones. No iPad screenshots are needed because the app
is iPhone-only. App icon is in the build; the 1024 px marketing copy is `store/graphics/ios/icon-1024.png`.

## Age rating questionnaire
Answer **None** / **No** to every content question (violence, horror, sexual content, profanity, alcohol or drugs,
gambling, contests, medical advice). Unrestricted web access: **No**. User-generated content: **No**.
Expected rating: **4+**. Confirm the result shown in App Store Connect.

## App Privacy ("nutrition label")
**Data Not Collected.** The app has no accounts, ads, analytics or third-party tracking. Saved games and
settings stay on the device. Purchases are handled by Apple. If you later add analytics or crash reporting,
update this and the privacy policy.

## Export compliance
Already declared in `Info.plist` (`ITSAppUsesNonExemptEncryption` = false): the app uses no encryption beyond
what the operating system provides.

## In-app purchase: Full Game
| Field | Value |
| --- | --- |
| Type | **Non-Consumable** |
| Reference name | Eldrin Full Game |
| Product ID | `eldrin_full_game` (must match `Entitlements.fullGameId` in the app) |
| Display name (30) | Full Game |
| Description (45) | Unlock the rest of the story. |
| Price | **[your choice]**; a typical starting point is the USD 3.99 tier |
| Family Sharing | Your choice (recommended: on) |
| Review screenshot | **[capture from a TestFlight or sandbox build]**: the unlock sheet showing the price |
| Review notes | "Shown when the player reaches the Drowned Gate after solving its riddle." |

Submit the IAP **together with the first app version**. It must be in "Ready to Submit" state to be attached.

**Promo codes for influencers:** create *Offer Codes* for this product in App Store Connect (Monetization >
In-App Purchases > the product > Offer Codes). Recipients redeem them with the "Have a code?" button in the game
or through the App Store. Check Apple's current limits and rules when you create them.

## App Review information
- **Sign-in required:** No. No demo account needed.
- **Contact:** **[first name, last name, phone, email]**
- **Notes:**
```
Eldrin is a text adventure. The first chapter is free; one non-consumable in-app purchase (eldrin_full_game)
unlocks the rest.

To reach the purchase screen quickly, type these commands one at a time (each followed by Send):
begin
w
n
w
take spectacles
e
s
e
n
give spectacles to wick
n
up
use oil on beacon
light beacon
down
s
s
e
e
e
say night and day
east

The unlock sheet then appears. It offers Buy, Restore purchase, and "Have a code?" (which opens Apple's
code redemption sheet). The game has no ads, no accounts and collects no data.
```

## Build and submit
1. `flutter build ipa --release` (needs a signing team set in Xcode), or archive from Xcode.
2. Upload with Transporter or Xcode Organizer, wait for processing, select the build on the 1.0.0 page.
3. Add `ios/Runner/PrivacyInfo.xcprivacy` to the **Runner** target in Xcode (File > Add Files, tick "Runner" target) so
   it is bundled. It declares no tracking, no collected data, and the one required-reason API the app uses
   (UserDefaults, via saved games and settings).

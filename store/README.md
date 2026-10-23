# Store submission kit

Everything needed to list Eldrin on the App Store and Google Play.

```
store/
  listing/app-store.md      every App Store Connect field, IAP details, review notes
  listing/google-play.md    every Play Console field, content rating, data safety, release steps
  listing/copy.json         the listing text (source of truth, within each store's limits)
  graphics/ios/             1024 icon, five 1320x2868 iPhone screenshots
  graphics/android/         512 icon, 1024x500 feature graphic, five 1080x1920 phone screenshots
docs/                       privacy policy, support page, landing page (host these)
ios/Runner/PrivacyInfo.xcprivacy   iOS privacy manifest
```

## Ready now
- Listing copy for both stores, checked against character limits
- Icons, feature graphic and five screenshots per platform, made from real gameplay
- Privacy policy, support page and landing page (`docs/`)
- Age rating, data safety and App Privacy answers (all "no data collected")
- Review notes with the exact commands to reach the paywall
- iOS export-compliance flag set; app is iPhone-only

## Only you can do these
| # | Task | Where |
| --- | --- | --- |
| 1 | Replace `[YOUR SUPPORT EMAIL]` and `[YOUR NAME OR COMPANY]` in `docs/support.html` and `docs/privacy.html` | `docs/` |
| 2 | Publish `docs/` (GitHub Pages: repo Settings > Pages > Deploy from branch `main`, folder `/docs`) and put the three URLs in both listings | GitHub |
| 3 | Decide the final **application ID** before the first upload (`app.eldrin.eldrin` can never change afterwards) | `android/app/build.gradle.kts`, Xcode bundle ID |
| 4 | Join Apple Developer Program (US$99/yr) and Google Play Console (US$25 once) | developer.apple.com, play.google.com/console |
| 5 | Create the in-app product `eldrin_full_game` in both stores and set the price | `listing/*.md` |
| 6 | Create the Android **upload keystore** and wire it into `build.gradle.kts` (release is currently signed with the debug key) | `android/app/` |
| 7 | Add `PrivacyInfo.xcprivacy` to the Runner target in Xcode, set your signing team | Xcode |
| 8 | Test real purchases: iOS sandbox/TestFlight, Android licence testers + internal track | stores |
| 9 | Capture the **in-app purchase review screenshot** (unlock sheet with price) from a TestFlight or sandbox build | iOS |
| 10 | Create influencer promo codes (Apple offer codes, Play promo codes) | store consoles |
| 11 | Fill in review contact details, copyright line, and answer the questionnaires | store consoles |
| 12 | Android new-account rule: closed test with 12+ testers for 14 days before production (check current Play policy) | Play Console |

## Regenerating the graphics
```sh
# 1. capture real screens (debug build; iOS simulator and Android emulator)
SHOT_DIR=store/screenshots/raw/ios     flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/store_screenshots_test.dart -d <ios simulator id>
SHOT_DIR=store/screenshots/raw/android flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/store_screenshots_test.dart -d <android emulator id>
# 2. compose
python3 tool/make_store_assets.py
```
Icon and splash art: `python3 tool/make_icons.py`.

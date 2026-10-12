# BeerCounter 0.9 🍺 / 🍸

Standardní konkurence piv počítaných na těch ošklivých Garminech! :-D

A native Apple Watch app that translates **active energy** into a playful drink-equivalent counter. This is a humorous metric, **not advice to consume alcohol**.

## Features

- First-launch wizard: choose beer 🍺 (0.5 L / 220 kcal) or prosecco 🍸 (0.2 L / 135 kcal), request HealthKit read permissions, then opt in to workout notifications or choose widget-only. The energy conversion is fixed and old customized values are ignored.
- Read-only HealthKit: daily active energy and workouts begun today.
- Rectangular Smart Stack widget and circular complication powered by cached data in a shared App Group. Tapping a complication opens the containing watch app; it refreshes HealthKit immediately on launch or on returning to the foreground. WidgetKit reloads may still be delayed.
- Localized CZ, EN, DE watch UI, widget, first-run wizard, information page (including alcohol safety warning), and five randomized workout notification messages per language.

## Device setup in Xcode

1. Open `BeerEarned.xcodeproj`, choose your Team for **BeerEarned Watch App** and **BeerEarnedWidgetExtension**.
2. For **both targets**: Signing & Capabilities → App Groups → register and select `group.cz.beerearned.shared`. The app group must be provisioned for the signing Team; source-control entitlements alone are insufficient.
3. In the Watch App target enable HealthKit and **HealthKit Background Delivery**. Its entitlement is already in source.
4. Run the app on a physical Apple Watch. The first-run wizard asks in order: drink → Apple Health read access → notifications / widget only. You can skip Health but the counter needs Health data to work.
5. Add the widget to Smart Stack or the circular complication to a supporting watch face.

If App Groups cannot be signed, the app still shows HealthKit data but the widget shows `—` rather than fake sample values.

## Semantics and limitations

- **Activity**: active energy from HealthKit workouts starting today.
- **Total today**: all of today's active energy (already including workouts); these are not added together.
- Workout notification: most recently completed, newly observed workout. Its count is based on that workout alone and is deduplicated. Old workouts do not trigger on first setup.
- HealthKit read permissions cannot be positively inspected per data type: a zero result may mean no samples or denied read permission.
- Background HealthKit data on watchOS can arrive up to hours later: `enableBackgroundDelivery` for these types is normally limited to hourly updates; the OS and WidgetKit also budget wake-ups. No guarantee of immediate notification or live widget refresh.
- Cache is scoped to the device's local day; widget displays `—` after midnight until fresh data arrive.
- Workouts crossing midnight are not yet apportioned; only those started today count towards Activity.

Localization uses `en.lproj`, `cs.lproj`, `de.lproj` `Localizable.strings` in app and widget. Add languages by creating further `.lproj` files. Notification variants reside as localized templates `notification_message_1...5`.

This code cannot be compiled by the GitHub connector. The watch app and previous widget behavior have been tested on physical Apple Watch; validate the final 0.9 layout with a fresh Xcode build.

## Watch user interface

- The dashboard keeps three small controls at the bottom: Settings (gear, left), Refresh (center), and Information (circled i, right).
- Information displays only the localized disclaimer exactly as supplied in Czech, with English and German translations.
- The dashboard automatically starts a HealthKit query when the user opens the watch app from its circular complication or returns to the foreground; manual refresh remains available.
- For onboarding tests on an already-configured debug installation, clear `settings.configured` from the shared user defaults or test a clean installation. iOS/watchOS won't necessarily display permission prompts twice if the user already decided.
- Not granting notifications saves widget-only mode; future changes are possible via Settings. The HealthKit authorization request's success callback does **not** reveal whether read access was granted.

## Compact counters and notification test

- The dashboard deliberately **does not show raw kcal counters**. Calculations still use the real HealthKit kcal behind the scenes.
- Prosecco counters use shorter localized glass-unit words (CZ `1 sklenka / 2 sklenky / 5 sklenek`, EN `glass / glasses`, DE `Glas / Gläser`); no repeating “prosecco” in the counters.
- The circular complication always shows the number plus the selected drink emoji (`4🍸` or `4🍺`) with a thin orange ring; no bottle, danger sign or skull. For 20 beers the full-screen text still uses `BASA (20 piv)`.
- To verify notification delivery without exercise, enable workout notifications in Settings, tap **Test notification**, return to the watch face and wait ~10 seconds. Foreground app notifications may not appear as a banner unless a notification center delegate explicitly requests foreground presentation.

## Version 0.9: compact widgets

- **Rectangular Smart Stack widget:** two short localized labels, **Aktivita** (workout activity) and **Dnes celkem** (total active energy today), each followed by its drink badge.
- **Circular watch-face complication:** always the exact count followed by the selected drink (e.g. `4🍸`, `7🍺`), enclosed by a **1.25-point orange ring**. No warning or bottle markers in this smallest format.
- **Rectangular badge rules:** Beer: 0–6 `N🍺`, 7–12 `N🍺⚠️`, 13+ `N☠️`. Prosecco: 0–3 `N🍸`, 4 `1🍾`, 5–7 `N🍸`, 8 `2🍾`, 9–12 `N🍸⚠️`, 13+ `N☠️`. On-screen app counts remain localized words.
- **Icon:** The same existing `BeerEarned_AppIcon_1024.png` artwork is included in the main Watch App's asset catalog. The widget extension retains its own icon asset.
- **Version:** `MARKETING_VERSION = 0.9` for all Xcode targets; build number remains 1.
- **Device test evidence:** first-run onboarding, HealthKit calorie readings, rectangular/circular widget propagation, and a scheduled test notification have been reported working on real Apple Watch. The final 0.9 display/layout needs an Xcode build and watch test.

## Third non-alcoholic option and app information

- Third drink: **Coca-Cola Original Taste** 🥤, **200 ml = 90 kcal** based on Czech-market nutritional information (45 kcal/100 ml). This is regular Coca-Cola with sugar, not Zero Sugar.
- The onboarding and Settings picker offer beer, prosecco, and Cola; the app and widgets use the same fixed kcal conversion. The rectangular widget uses a simple N🥤 count for Cola, without alcohol-only danger or bottle milestones.
- The information page explains all daily movement vs saved Apple Health workouts, local-only data handling, alcohol-theme age eligibility (at least 18, or a higher local legal age), and retains the existing alcohol/driving warning.
- The existing application contains no developer-controlled network data upload or analytics SDK. Apple's own Apple Health/iCloud synchronization is separate; a legal privacy notice and accurate App Store privacy answers still need final review before distribution.
- The app currently does **not** implement technical age verification; the adult-use notice is informational. Do not claim that the app enforces a legal age gate.
- Both recorded-workout-only and all-movement modes continue to work for the Cola option. Notifications show the chosen drink icon, including test notifications.

# BeerEarned 🍺 / 🍸

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

This PR has **not** been compiled with Xcode in this environment; test builds and the actual provisioning of App Groups on a physical watch before merging.

## Watch user interface

- The dashboard keeps three small controls at the bottom: Settings (gear, left), Refresh (center), and Information (circled i, right).
- Information displays only the localized disclaimer exactly as supplied in Czech, with English and German translations.
- The dashboard automatically starts a HealthKit query when the user opens the watch app from its circular complication or returns to the foreground; manual refresh remains available.
- For onboarding tests on an already-configured debug installation, clear `settings.configured` from the shared user defaults or test a clean installation. iOS/watchOS won't necessarily display permission prompts twice if the user already decided.
- Not granting notifications saves widget-only mode; future changes are possible via Settings. The HealthKit authorization request's success callback does **not** reveal whether read access was granted.

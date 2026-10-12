# BeerCounter — release roadmap

## 0.9 — device-tested beta (current)
- HealthKit active energy; workouts and today's total
- Localized CZ / EN / DE, first-run permissions, watch app and rectangular/circular widgets
- On-device test notification confirmed received on Apple Watch
- Rectangular widget uses semantic system `Font.body` for both captions and values (with one-line minimum scaling)
- Needs visual test of this typography and real completed-workout notifications

## 1.0 — first App Store release
- Confirm completion notifications and tune localized message templates in real workouts
- Run release build, check icon, complications, permissions and localization on a physical watch
- Prepare Apple Developer Program membership, distribution signing, App Store Connect listing, screenshots, app privacy disclosures, and submission to review
- Review Apple App Store policy risks related to alcohol-themed rewards and HealthKit data. The in-app disclaimer does not guarantee approval

## 1.1 — Pouze aktivita / workouts-only mode (early implementation, device test pending)
- Opt-in setting **Pouze aktivita** (EN **Workouts only**, DE **Nur Trainings**), initially off to preserve current behavior.
- OFF: rectangular widget shows **Aktivita** and **Dnes celkem**, circular complication shows today's total active-energy drink equivalents, main app shows both rows.
- ON: rectangular widget and main app show just one **Aktivita** row, and circular complication shows the activity-only drink count. Workout notification summary counts use the selected mode.
- Reuse read-only HealthKit `HKWorkout` workout energy (not all active movement). This does **not** rigorously prove the workout was manually started: automatically recognized or third-party imported workouts can appear as `HKWorkout`. Reliable manual-only filtering requires a separate, explicitly defined source strategy.
- Persist the setting in shared App Group; send WidgetKit reload when changed. Expect system-delayed rendering in some circumstances.
- Test both settings on physical Apple Watch and verify dashboard, rectangular widget, circular complication, and notifications.

## 2.0 — weekly progress
- Retain daily activity and workout snapshots Monday through Sunday, with week boundaries in the user's local time zone
- Show seven-day history and weekly summary in the watch app
- Send a Monday-morning summary notification with the *previous* completed week's figures, best effort subject to watchOS background scheduling limits
- Handle timezone changes, Monday rollover, HealthKit data corrections, and periods in which the app is not opened

## 3.0 — optional multiplayer leaderboard
- Pseudonyms and opt-in comparisons with friends or groups
- Weekly normalized scoring and anti-abuse checks; decide whether to compare raw active calories, earned equivalent units, or activity goals
- Privacy-by-design: permission to share limited aggregate scores, secure account/backend, data export/deletion and abuse moderation
- Never make HealthKit data public by default

## 4.0 — suggested idea, not agreed
- **A virtual brewery/collection game**: movement unlocks decorative buildings, badges, seasonal challenges and cosmetic upgrades, without implying actual alcohol should be consumed
- Reuses version 2 history and version 3 friends; unlocks collectibles based on consistency and personal milestones rather than amounts consumed
- Keep visuals and game rules carefully distinguished from encouragement to drink

## 5.0 — Calendar of rare seasonal badges (proposal)

**Mechanic: the Calendar Passport.** On a handful of special dates each year, the watch offers a time-limited activity challenge. Completing one adds an illustrated, year-stamped collectible badge to a permanent calendar album. These are **virtual rewards for movement, not for drinking**, and they do not multiply drink equivalents or incentivize alcohol consumption.

### Four founding events

| Local occasion | Badge | Suggested theme |
| --- | --- | --- |
| December 24 — Christmas Eve (CZ seasonal edition) | **Zlaté prasátko** / Golden Piglet | A small golden pig from a pre-holiday walk; no fasting or eating rules |
| December 31 — New Year's Eve | **Poslední otočka** / Final Lap | End the year with some movement, not a drinking challenge |
| June solstice (astronomical date in the user's local timezone) | **Dítě slunce** / Sun Child | Celebrate the longest daylight period in the Northern Hemisphere |
| December solstice (astronomical date in the user's local timezone) | **Strážce světla** / Keeper of Light | Mark the return of longer days with a small amount of movement |

Seasonal names/artwork should be localized or region-appropriate in CZ/EN/DE; December 24 is a Czech-specific themed event, not assumed to be a universal holiday. Future optional editions can cover the two equinoxes, birthdays (opt-in) and other country-specific holidays.

### Unlock and collection rules

1. **Availability:** The event is valid for one local calendar day, 00:00–23:59:59. For solstices, resolve the actual astronomical occurrence to the user's local date using a vetted yearly table or suitable astronomical calculation; do not assume it is always June 21 / December 21.
2. **Achievable goal:** Unlock when HealthKit confirms **either at least 15 minutes of completed workout time or at least 100 active kcal during that day**, with an accessible, optionally personalized alternative considered before implementation. Values are provisional and should be user-tested, especially for varied fitness and disability needs.
3. **No need to open the app on the holiday:** On the next HealthKit sync/open, retroactively check that day's data and award the badge even if watchOS could not wake the app on the event day. Once earned, the same event/year cannot be granted twice. No guarantee of an instantaneous background notification.
4. **Collectible album:** Group year-stamped badges by year. Completing all four founding events in a year unlocks the rare **Strážce kalendáře** / Calendar Keeper meta-badge. Repeating an event in subsequent years adds that year's stamp rather than overwriting the earlier one.
5. **Long-term progression:** Repeating the same event in 2 separate years unlocks a silver frame and in 3 separate years a gold frame. Missing a year never removes a badge or resets other progress.
6. **Respect privacy and device limits:** Derive badges from read-only HealthKit data; store only the minimally necessary event/date/achievement record on-device to start, and design optional cross-device sync separately. Define timezone/DST handling, HealthKit edits/deletions, reinstall recovery and duplicate-prevention rules before production.
7. **Notifications are optional:** A localized congratulatory alert can be sent once after a new unlock is detected, with user consent. watchOS background delivery is best-effort, so show the reward again in the app when opened.

### Optional future expansion

- Rare **surprise editions** revealed only on their day, with discoverable clues in the app; publish eligibility fairly so a background-delivery delay cannot unfairly deny a badge.
- Design a small animated badge-reveal screen and optional display of a favorite collectible in the Smart Stack widget.
- A multiplayer season could compare *collected badges* (opt-in) rather than raw HealthKit scores, with no reward for alcohol consumption.

This is a planning document, not a release commitment.

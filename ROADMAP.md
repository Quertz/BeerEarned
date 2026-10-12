# BeerEarned — release roadmap

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

This is a planning document, not a release commitment.

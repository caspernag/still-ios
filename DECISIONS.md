# Decisions and assumptions

Choices made where the brief was ambiguous, picked to be the most Apple-native,
robust and simple option.

## Project and tooling

- **Repository.** The old RFID C# project was removed (owner approval) and Still lives at the repo root.
  The work is pushed to `caspernag/still-ios`.
- **Built on Linux, verified on macOS CI.** The authoring environment had no Xcode. XcodeGen was built
  from source on Linux to generate `Still.xcodeproj`; the iOS build and all tests run on GitHub Actions
  `macos-26` runners (`.github/workflows/ci.yml`). The platform-independent core is also tested on Linux.
- **Shared code is a local Swift package** (`StillKit/`) with three products: `StillCore` (pure
  Foundation: sessions, stats, schedules, storage; no Apple-only imports), `StillKit` (Screen Time and
  ActivityKit glue) and `DesignSystem` (tokens, typography, components, Live Activity views). Every
  target links what it needs, so the app and the four extensions share one implementation.
- **Swift 6 language mode** with complete concurrency checking everywhere.
- **iOS 17.0 minimum**, as specified. APIs from 17.2+ are behind `#available`.

## Design system

- **The design's 60 px top padding is the safe area**, so screens add no extra top padding; the
  34 px bottom is the home-indicator inset, so buttons sit 8 pt above the safe area.
- **Dark mode** uses a deep ink paper (#121417), lifted surfaces (#1C1F24) and the same apricot.
  The primary button inverts (light gradient, ink label) because an ink button on an ink
  background would disappear.
- **Session-complete ring and check** use green #49DE24 from the artboard (token `success`).
- **Dynamic Type** scales every style relative to the matching iOS text style; very large display
  numbers (hero, stat, timer) are capped so nothing clips. The whole app is capped at
  `accessibility2`. Every screen sits in a scroll view that only scrolls when content is taller than
  the screen.
- **No fake status bar** is drawn anywhere except the demo-only Lock Screen backdrop used for the
  Live Activity screenshot.

## Screens and behavior

- **Choose apps** uses `FamilyActivityPicker` (iOS can't list apps). The design's toggle list becomes a
  summary card with the count and up to eight icons.
- **"Blocking 2 apps and 3 categories"** (Home and Choose apps) shows the real app and category
  icons underneath (`Label(token).labelStyle(.iconOnly)` in small tiles, apps first, "+N" when
  there are more) instead of a line of names. Owner request: as visual as possible.
- **Custom duration** is a fifth segment labelled "Custom" (or the custom value once set). Free users
  get the paywall. If Pro lapses, a saved custom duration silently falls back to 30 minutes.
- **The "Be still" circle and "Start session"** both start a session. With nothing selected, Choose apps
  opens first and the session starts automatically after "Done".
- **Ended-early dialog** is a custom overlay matching artboard 8 (not a system alert). An early end of
  less than one minute says "You took a pause. That still counts." No shame copy anywhere.
- **Strict mode** can't be toggled while a session runs.
- **Session complete** appears when the app becomes active after a completed session (or live, if the
  app is open when the timer ends). Early ends never show it.
- **Automatic paywall** appears once, after the user dismisses the first "Session complete" screen
  (either "Done" or "Go again"; with "Go again" the new session starts when the paywall closes).
- **Notification permission** is requested when the first "Session complete" appears, and again only
  if the user turns "Notify when done" on. The first session therefore can't notify; that is the
  brief's intended trade-off.
- **Review prompt** is requested once, 1.2 s after the 3rd "Session complete" appears.
- **Insights** is opened by tapping the Home stat. It shows 7 days of reclaimed minutes (accent bars),
  streak, sessions, urges resisted and the daily average.
- **Schedules** list: name, time range and days, plus a toggle. Add/edit in a sheet with name, start,
  end and weekday chips. Schedules use the Home selection. With no selection, nothing is registered.
- **Settings "Still Pro" row** shows "Free trial · N days left", "Active", or "Try it free for 7 days"
  with a "Try free" button that opens the paywall. A small "Pro" badge marks gated rows for free users.
- **Settings → About** also has "Terms" (not in the artboard) because Guideline 3.1.2 wants the
  terms reachable in the app.

## Screen Time

- **Each schedule gets one activity per weekday** (weekly repeating). A schedule that runs every day
  collapses into a single daily activity, because DeviceActivityCenter allows at most 20 monitored
  activities. One slot is always reserved for a manual session; enabling more schedules than fit shows
  an error and keeps the previous state.
- **Overnight schedules** (end ≤ start, e.g. 22:00–07:00) end on the following weekday.
- **Separate ManagedSettingsStores**: `still.session` for manual sessions and
  `still.schedule.<uuid>` per schedule, so they never clear each other.
- **Categories also shield websites in those categories** (`webDomainCategories`).
- **The session activity is one-off** with full date components (incl. seconds and time zone), from
  "now" to the end. Durations are validated to 15 min … 12 h in `SessionMath` and in the UI.
- **The monitor only finalizes the session its activity belongs to.** A late `intervalDidEnd` for an
  older session can't unlock a newer one. All finalization is idempotent (monitor and app may both try).
- **Without Pro, schedules are unregistered** (their on/off flags are kept and restored with Pro).
- **Urges resisted** are stored as timestamps (kept 60 days). A session's count is the taps during its
  interval; Insights counts all taps in the last 7 days (sessions and schedules).
- **The shield's secondary button** shows "You chose this at 21:45." and returns `.none`. The design's
  "6 minutes ago" isn't used because the system caches shield configurations, so relative times go stale.
- **The shield icon** is an asset-catalog image (light and dark), not drawn at runtime, to keep the
  extension small.

## Data

- **Storage** is Codable JSON in the App Group's `UserDefaults`, one key per value, so a write from one
  process (e.g. the ShieldAction extension) never overwrites another's.
- **Streak** = consecutive calendar days (in the current calendar and time zone) with at least one
  completed session or an early end of 10 minutes or more. A session belongs to the day it **started**.
  The streak stays alive through today if yesterday counted.
- **This week** follows the locale's first weekday (Monday in Norway).
- **Reclaimed time** sums completed time in seconds (partial minutes count) and is displayed rounded
  down to whole minutes. It never exceeds the planned duration.
- **Seeded schedule** "Nights 22:00–07:00" (every day, off).

## Subscriptions

- **SubscriptionStoreView** with `productIDs` (no hard-coded group ID), `.picker` control style,
  multiline button label, visible restore and policy buttons, custom terms/privacy URLs, and our own
  close button. StoreKit renders prices and the trial terms, which keeps the paywall compliant
  with 3.1.2 in every storefront. The design's "Best value" badge isn't reproduced, because StoreKit
  controls those rows.
- **Trial detection** uses `Transaction.offer?.type == .introductory` on iOS 17.2+ and
  `offerType` before that. Days left are rounded up.
- **Products and prices**: yearly 29.99 USD and monthly 4.99 USD, both with a 1-week free trial,
  in group "Still Pro". The yearly plan ranks higher (upgrade path).

## Privacy

- **PrivacyInfo.xcprivacy** in the app and every extension: no tracking, no collected data, and
  UserDefaults with reasons **CA92.1** (as requested) and **1C8F.1** (App Group access, which Still
  needs because the extensions read the same defaults).
- **App Privacy label**: Data Not Collected.

## Demo mode

- `-StillDemo` (plus `-StillDemoSkipOnboarding`, `-StillDemoPro`, `-StillDemoHistory`,
  `-StillDemoScreen <session|shield|liveActivity|chooseApps|insights|paywall|settings>`).
  All parsing and demo types sit inside `#if DEBUG`, so Release builds can't enter demo mode.
- Demo mode uses an isolated `UserDefaults` suite that is reset on every launch, a fake
  "3 categories" selection, and a clock that "Demo: fast-forward" can jump to the session end.
- The shield and the Live Activity can't be captured by UI tests, so demo mode renders the same views
  in-app for screenshots (`DemoScreens.swift`, DEBUG only).

## Language

- **English only**, by the owner's decision ("Be still" everywhere). No String Catalogs are
  shipped; dates and times still follow the device region (e.g. 24-hour time in Norway), and lists
  like "2 apps and 3 categories" are always formatted in English. System UI (Screen Time picker,
  StoreKit sheets) follows the device language, as iOS decides.
